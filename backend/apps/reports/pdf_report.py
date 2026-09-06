"""Comprehensive PDF financial report generator using reportlab.

Page 1  — Cover / Business Details only (tenant name, contact info, address, period)
Page 2+ — Executive Summary KPIs, trends, ratios, then revenue/cost charts,
          P&L statement, and vehicle ROI tables
"""

import io
from datetime import datetime
from decimal import Decimal

from django.db.models import Sum, F
from django.http import HttpResponse
from django.utils import timezone
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.graphics.shapes import Drawing, String
from reportlab.graphics.charts.piecharts import Pie
from reportlab.lib.utils import ImageReader
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    PageBreak,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)
from reportlab.platypus.flowables import HRFlowable

# Brand colors
BRAND_INDIGO = colors.HexColor('#4f46e5')
BRAND_DARK   = colors.HexColor('#1e293b')
BRAND_GREY   = colors.HexColor('#64748b')
BRAND_GREEN  = colors.HexColor('#166534')
BRAND_RED    = colors.HexColor('#991b1b')
BRAND_AMBER  = colors.HexColor('#d97706')
BRAND_BLUE   = colors.HexColor('#2563eb')
BRAND_LIGHT  = colors.HexColor('#f1f5f9')
BRAND_PURPLE = colors.HexColor('#6b21a8')

PIE_COLORS = [
    colors.HexColor('#6366f1'), colors.HexColor('#f59e0b'), colors.HexColor('#10b981'),
    colors.HexColor('#ef4444'), colors.HexColor('#3b82f6'), colors.HexColor('#ec4899'),
    colors.HexColor('#8b5cf6'), colors.HexColor('#64748b'), colors.HexColor('#dc2626'),
    colors.HexColor('#f97316'), colors.HexColor('#0e7490'), colors.HexColor('#4338ca'),
]


def _cur_label(tenant):
    """Return the currency symbol for a tenant."""
    cmap = {
        'USD': '$', 'EUR': '€', 'GBP': '£', 'KES': 'KSh', 'NGN': '₦',
        'ZAR': 'R', 'AED': 'AED', 'SAR': 'SAR', 'INR': '₹', 'CAD': 'C$',
        'AUD': 'A$', 'JPY': '¥', 'CNY': '¥', 'BRL': 'R$', 'GHS': '₵',
        'TZS': 'TSh', 'UGX': 'USh', 'RWF': 'FRw', 'ETB': 'Br',
    }
    return cmap.get(getattr(tenant, 'currency', 'USD'), '$')


def _fmt(n, cur=''):
    """Format a number with thousands separators and optional currency prefix."""
    try:
        n = float(n)
    except (TypeError, ValueError):
        n = 0.0
    if n < 0:
        return f'-{cur}{abs(n):,.0f}'
    return f'{cur}{n:,.0f}'


def _make_legend(colors_list, labels, x, y, font_size=7, box_size=8, row_height=12):
    """Create a Legend widget for chart series."""
    from reportlab.graphics.charts.legends import Legend
    leg = Legend()
    leg.x = x
    leg.y = y
    leg.colorNamePairs = list(zip(colors_list, labels))
    leg.fontName = 'Helvetica'
    leg.fontSize = font_size
    leg.boxAnchor = 'nw'
    leg.columnMaximum = 1
    leg.alignment = 'right'
    leg.dx = box_size
    leg.dy = box_size
    leg.deltay = row_height
    leg.dxTextSpace = 4
    leg.strokeWidth = 0.5
    return leg


def _draw_pie(title, data, width=420, height=200):
    """Return a Drawing with a pie chart + legend.

    data = list of (label, value) tuples
    """
    total = sum(v for _, v in data) or 1
    angles = [(v / total) * 360 for _, v in data]
    d = Drawing(width + 200, height + 20)
    d.add(String(width / 2, height + 5, title, textAnchor='middle',
                 fontName='Helvetica-Bold', fontSize=11, fillColor=BRAND_DARK))
    pie = Pie()
    pie.x = 20
    pie.y = 15
    pie.width = height
    pie.height = height
    pie.slices.strokeWidth = 1
    pie.slices.strokeColor = colors.white
    for i in range(len(data)):
        pie.slices[i].fillColor = PIE_COLORS[i % len(PIE_COLORS)]
        pie.slices[i].popout = 0
    pie.data = angles
    pie.startAngle = 90
    pie.direction = 'clockwise'
    d.add(pie)
    # Legend on the right
    top_n = min(len(data), 10)
    labels = [f'{lbl} ({v / total * 100:.0f}%)' for lbl, v in data[:top_n]]
    if labels:
        leg = _make_legend(
            [PIE_COLORS[i % len(PIE_COLORS)] for i in range(top_n)],
            labels, x=height + 40, y=height - 10, font_size=7, row_height=11,
        )
        d.add(leg)
    return d


def _draw_bar(title, data, width=420, height=200, color=None):
    """Return a Drawing with a vertical bar chart.

    data = list of (label, value) tuples
    """
    from reportlab.graphics.charts.barcharts import VerticalBarChart

    n = len(data)
    d_w = width + 100
    d_h = height + 40
    d = Drawing(d_w, d_h)
    d.add(String(d_w / 2, d_h - 12, title, textAnchor='middle',
                 fontName='Helvetica-Bold', fontSize=11, fillColor=BRAND_DARK))

    chart_w = width - 40
    chart_h = height - 25
    bc = VerticalBarChart()
    bc.x = 50
    bc.y = 25
    bc.width = chart_w
    bc.height = chart_h
    bc.data = [[v for _, v in data]]
    bc.categoryAxis.categoryNames = [lbl for lbl, _ in data]
    bc.categoryAxis.labels.fontName = 'Helvetica'
    bc.categoryAxis.labels.fontSize = 8
    bc.categoryAxis.labels.boxAnchor = 'ne'
    bc.categoryAxis.labels.dy = -10
    bc.categoryAxis.labels.angle = 35 if n > 8 else 0
    bc.valueAxis.labels.fontName = 'Helvetica'
    bc.valueAxis.labels.fontSize = 8
    bc.valueAxis.valueMin = 0
    bc.valueAxis.valueMax = max((v for _, v in data), default=1) * 1.1
    bc.bars[0].fillColor = color or BRAND_INDIGO
    bc.bars[0].strokeColor = None
    bc.barWidth = max(4, chart_w / max(n, 1) * 0.6)
    bc.groupSpacing = max(4, chart_w / max(n, 1) * 0.2)
    d.add(bc)
    return d


def _draw_hbar(title, data, width=420, height=200, color=None):
    """Return a Drawing with a horizontal bar chart.

    data = list of (label, value) tuples
    """
    from reportlab.graphics.charts.barcharts import HorizontalBarChart

    n = len(data)
    d_w = width + 120
    d_h = height + 40
    d = Drawing(d_w, d_h)
    d.add(String(d_w / 2, d_h - 12, title, textAnchor='middle',
                 fontName='Helvetica-Bold', fontSize=11, fillColor=BRAND_DARK))

    chart_x = 85
    chart_y = 20
    chart_w = width - 20
    chart_h = height - 30
    bc = HorizontalBarChart()
    bc.x = chart_x
    bc.y = chart_y
    bc.width = chart_w
    bc.height = chart_h
    bc.data = [[v for _, v in data]]
    bc.categoryAxis.categoryNames = [lbl for lbl, _ in data]
    bc.categoryAxis.labels.fontName = 'Helvetica'
    bc.categoryAxis.labels.fontSize = 8
    bc.categoryAxis.labels.boxAnchor = 'e'
    bc.categoryAxis.labels.dx = -3
    bc.valueAxis.labels.fontName = 'Helvetica'
    bc.valueAxis.labels.fontSize = 7
    bc.valueAxis.valueMin = 0
    bc.valueAxis.valueMax = max((v for _, v in data), default=1) * 1.1
    bc.bars[0].fillColor = color or BRAND_INDIGO
    bc.bars[0].strokeColor = None
    bc.barWidth = max(4, chart_h / max(n, 1) * 0.6)
    bc.groupSpacing = max(4, chart_h / max(n, 1) * 0.2)
    d.add(bc)
    return d


def _draw_line_area(title, data, series_labels, width=420, height=200,
                    series_colors=None):
    """Return a Drawing with a line+area chart.

    data = list of dicts: [{'date': '2025-01-01', 'revenue': 100, 'payments': 80}, ...]
    series_labels = list of label strings for each data key (excluding 'date')
    series_colors = list of colors for each series
    """
    from reportlab.graphics.charts.lineplots import LinePlot
    from reportlab.graphics.shapes import PolyLine, Rect, String as DrawString

    n = len(data)
    if n < 2:
        return Drawing(1, 1)
    d_w = width + 80
    d_h = height + 50
    d = Drawing(d_w, d_h)
    d.add(String(d_w / 2, d_h - 14, title, textAnchor='middle',
                 fontName='Helvetica-Bold', fontSize=11, fillColor=BRAND_DARK))

    chart_x = 55
    chart_y = 30
    chart_w = width - 15
    chart_h = height - 25

    lp = LinePlot()
    lp.x = chart_x
    lp.y = chart_y
    lp.width = chart_w
    lp.height = chart_h

    sample = data[0]
    keys = [k for k in sample if k != 'date'] if sample else []
    colors_list = series_colors or [BRAND_INDIGO, BRAND_GREEN]
    all_vals = []
    plots = []
    for i, key in enumerate(keys):
        points = [(j, float(t.get(key, 0) or 0)) for j, t in enumerate(data)]
        all_vals.extend([v for _, v in points])
        plots.append(points)

    lp.data = plots
    max_val = max(all_vals, default=1) * 1.15
    if max_val == 0:
        max_val = 1
    lp.joinedLines = 1
    for i in range(len(keys)):
        c = colors_list[i % len(colors_list)]
        lp.lines[i].strokeColor = c
        lp.lines[i].strokeWidth = 1.5
        lp.lines[i].fillColor = colors.Color(c.red, c.green, c.blue, alpha=0.15)
    lp.xValueAxis.valueMin = 0
    lp.xValueAxis.valueMax = n - 1
    lp.xValueAxis.valueStep = max(1, int((n - 1) / min(n, 10)))
    lp.xValueAxis.labels.fontName = 'Helvetica'
    lp.xValueAxis.labels.fontSize = 7
    lp.xValueAxis.labels.angle = 30
    lp.xValueAxis.labels.boxAnchor = 'ne'
    lp.xValueAxis.labels.dy = -8
    lp.xValueAxis.labelTextFormat = lambda x: data[int(x)].get('date', '')[:10] if 0 <= int(x) < n else ''
    lp.yValueAxis.valueMin = 0
    lp.yValueAxis.valueMax = max_val
    lp.yValueAxis.labels.fontName = 'Helvetica'
    lp.yValueAxis.labels.fontSize = 7
    d.add(lp)

    if series_labels:
        leg = _make_legend(
            [colors_list[i % len(colors_list)] for i in range(len(series_labels))],
            series_labels, x=chart_x + 5, y=chart_y + chart_h - 3,
            font_size=7, row_height=10,
        )
        d.add(leg)
    return d


def generate_financial_pdf(tenant, overview, revenue, costs, roi_data, period_str,
                           sections=None):
    """Generate the comprehensive financial report PDF.

    Args:
        tenant: The Tenant model instance.
        overview: dict with summary + trends from financial_overview.
        revenue: dict from revenue_breakdown.
        costs: dict from cost_breakdown.
        roi_data: list from vehicle_roi.
        period_str: human-readable period string.
        sections: optional set/list of section keys to include. If None, all are included.
            Valid keys: business_details, executive_summary, revenue_charts,
                        cost_analysis, profit_loss, vehicle_roi.

    Returns:
        HttpResponse with application/pdf content.
    """
    # Default: include all sections
    all_sections = {'business_details', 'executive_summary', 'revenue_charts',
                    'cost_analysis', 'profit_loss', 'vehicle_roi'}
    if sections is None:
        sections = all_sections
    else:
        sections = set(sections) & all_sections
        if not sections:
            sections = all_sections
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib import colors as rl_colors

    from apps.rentals.models import (
        RentalAgreement, RentalPayment, RentalCharge
    )

    cur = _cur_label(tenant)
    output = io.BytesIO()

    # ── Styles ──
    styles = getSampleStyleSheet()

    style_cover_title = ParagraphStyle(
        'CoverTitle', parent=styles['Title'],
        fontSize=28, textColor=BRAND_INDIGO, alignment=TA_CENTER,
        spaceAfter=6, fontName='Helvetica-Bold'
    )
    style_cover_sub = ParagraphStyle(
        'CoverSub', parent=styles['Title'],
        fontSize=14, textColor=BRAND_GREY, alignment=TA_CENTER,
        spaceAfter=4, fontName='Helvetica'
    )
    style_cover_label = ParagraphStyle(
        'CoverLabel', parent=styles['Normal'],
        fontSize=9, textColor=BRAND_GREY, alignment=TA_LEFT,
        fontName='Helvetica'
    )
    style_cover_value = ParagraphStyle(
        'CoverVal', parent=styles['Normal'],
        fontSize=12, textColor=BRAND_DARK, alignment=TA_LEFT,
        fontName='Helvetica-Bold'
    )
    style_kpi_label = ParagraphStyle(
        'KPILabel', parent=styles['Normal'],
        fontSize=8, textColor=BRAND_GREY, alignment=TA_CENTER,
        fontName='Helvetica'
    )
    style_kpi_value = ParagraphStyle(
        'KPIValue', parent=styles['Normal'],
        fontSize=16, textColor=BRAND_DARK, alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    style_section = ParagraphStyle(
        'Section', parent=styles['Heading2'],
        fontSize=13, textColor=BRAND_INDIGO, fontName='Helvetica-Bold',
        spaceBefore=14, spaceAfter=4
    )
    style_chart_title = ParagraphStyle(
        'ChartTitle', parent=styles['Heading3'],
        fontSize=11, textColor=BRAND_DARK, fontName='Helvetica-Bold',
        spaceBefore=2, spaceAfter=0, alignment=TA_CENTER
    )
    style_normal = styles['Normal']

    # ── Page templates ──
    page_w, page_h = A4
    margin = 20 * mm
    frame = Frame(margin, margin, page_w - 2 * margin, page_h - 2 * margin, id='normal')

    def _cover_page(canvas, doc):
        """Draw cover page decorations.

        Shows the tenant's business name (not the system name) and the
        tenant's logo when one is available.
        """
        canvas.saveState()
        # Indigo banner at top
        canvas.setFillColor(BRAND_INDIGO)
        canvas.rect(0, page_h - 80, page_w, 80, fill=True, stroke=False)
        canvas.setFillColor(colors.white)

        biz_name = tenant.full_name or tenant.short_name or 'Business'
        # Draw tenant logo on left side of banner if available
        if getattr(tenant, 'logo', None) and tenant.logo:
            try:
                # Read the logo into memory so it works with both local
                # FileSystemStorage and S3Boto3Storage (which has no .path())
                import io as _io
                tenant.logo.open('rb')
                try:
                    img_bytes = tenant.logo.read()
                finally:
                    tenant.logo.close()
                img = ImageReader(_io.BytesIO(img_bytes))
                img_w, img_h = img.getSize()
                # Fit logo within a 50x50 box inside the indigo banner
                max_box = 50
                scale = min(max_box / img_w, max_box / img_h)
                draw_w = img_w * scale
                draw_h = img_h * scale
                logo_x = margin
                logo_y = page_h - 80 + (80 - draw_h) / 2
                # White rounded rectangle behind the logo for contrast
                canvas.setFillColor(colors.white)
                canvas.roundRect(logo_x - 4, logo_y - 4, draw_w + 8, draw_h + 8, 6, fill=True, stroke=False)
                canvas.drawImage(img, logo_x, logo_y, draw_w, draw_h, mask='auto')
            except Exception:
                # If the logo file can't be read, just skip it
                pass

        # Center the business name in the banner
        canvas.setFont('Helvetica-Bold', 20)
        canvas.drawCentredString(page_w / 2, page_h - 50, biz_name)
        canvas.setFont('Helvetica', 9)
        canvas.drawCentredString(page_w / 2, page_h - 65, 'Financial Report')
        canvas.setFillColor(BRAND_INDIGO)
        canvas.rect(0, 0, page_w, 4, fill=True, stroke=False)
        canvas.restoreState()

    def _content_page(canvas, doc):
        """Draw header/footer for content pages."""
        canvas.saveState()
        canvas.setFillColor(BRAND_INDIGO)
        canvas.rect(0, page_h - 20, page_w, 20, fill=True, stroke=False)
        canvas.setFillColor(colors.white)
        canvas.setFont('Helvetica-Bold', 9)
        biz_name = tenant.full_name or tenant.short_name or 'Business'
        canvas.drawString(margin, page_h - 14, f'{biz_name} — Financial Report')
        canvas.setFont('Helvetica', 8)
        canvas.drawRightString(page_w - margin, page_h - 14, period_str)
        # footer
        canvas.setFillColor(BRAND_GREY)
        canvas.setFont('Helvetica', 7)
        canvas.drawCentredString(page_w / 2, 12, f'Page {doc.page}  ·  Powered by DomendraFleet')
        canvas.restoreState()

    from reportlab.platypus import PageTemplate

    cover_template = PageTemplate(id='cover', frames=[frame], onPage=_cover_page)
    content_template = PageTemplate(id='content', frames=[frame], onPage=_content_page)
    doc = BaseDocTemplate(
        output, pagesize=A4,
        leftMargin=margin, rightMargin=margin,
        topMargin=margin, bottomMargin=margin,
        pageTemplates=[cover_template, content_template],
    )

    elements = []
    s = overview.get('summary', {}) if overview else {}
    trends = overview.get('trends', {}) if overview else {}

    # ── Helper: track whether any content section has been added ──
    _content_started = [False]

    def _start_content():
        """Insert PageBreak with content template for the first content section."""
        if not _content_started[0]:
            elements.append(PageBreak(nextTemplate='content'))
            _content_started[0] = True
        else:
            elements.append(PageBreak())

    # ══════════════════════════════════════════════
    # PAGE 1 — Business / Cover details
    # ══════════════════════════════════════════════
    if 'business_details' in sections:
        elements.append(Spacer(1, 60))
        elements.append(Paragraph('Financial Report', style_cover_title))
        elements.append(Paragraph(period_str, style_cover_sub))
        elements.append(Spacer(1, 30))

        # Business details table
        biz_rows = [
            ['Business Name', tenant.full_name or tenant.short_name],
            ['Short Name', tenant.short_name],
            ['Email', tenant.email],
            ['Phone', tenant.mobile_number or '—'],
            ['Country', tenant.country or '—'],
            ['Address', tenant.address or '—'],
            ['Currency', tenant.currency or 'USD'],
            ['Report Period', period_str],
            ['Report Generated', datetime.now().strftime('%Y-%m-%d %H:%M')],
        ]
        biz_data = []
        for label, val in biz_rows:
            biz_data.append([
                Paragraph(label, style_cover_label),
                Paragraph(str(val), style_cover_value),
            ])
        biz_table = Table(biz_data, colWidths=[60 * mm, 100 * mm])
        biz_table.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('LINEBELOW', (0, 0), (-1, -2), 0.5, BRAND_LIGHT),
            ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ]))
        elements.append(biz_table)

    # ══════════════════════════════════════════════
    # PAGE 2 — Executive Summary
    # ══════════════════════════════════════════════
    if 'executive_summary' in sections:
        _start_content()
        elements.append(Paragraph('Executive Summary', style_section))
        elements.append(Spacer(1, 8))

        # ── KPI cards: 2 rows × 3 columns ──
        col_w = (page_w - 2 * margin) / 3

        def _kpi_card(label, value, color=BRAND_DARK, sub_text=''):
            """Build a single KPI card cell with a colored accent bar at top."""
            style_card_value = ParagraphStyle(
                'cv', parent=style_kpi_value, fontSize=14, textColor=color,
                spaceBefore=2, spaceAfter=0,
            )
            style_card_label = ParagraphStyle(
                'cl', parent=style_kpi_label, fontSize=7, textColor=BRAND_GREY,
                spaceBefore=0, spaceAfter=0,
            )
            style_card_sub = ParagraphStyle(
                'cs', parent=style_kpi_label, fontSize=6, textColor=BRAND_GREY,
                spaceBefore=1, spaceAfter=0,
            )
            inner = [Paragraph(label.upper(), style_card_label),
                     Paragraph(value, style_card_value)]
            if sub_text:
                inner.append(Spacer(1, 20))
                inner.append(Paragraph(sub_text, style_card_sub))
            return inner

        kpi_cards = [
            _kpi_card('Total Revenue', _fmt(s.get('revenue', 0), cur), BRAND_GREEN),
            _kpi_card('Total Costs', _fmt(s.get('total_costs', 0), cur), BRAND_RED,
                      f"OpEx {_fmt(s.get('operating_costs', 0), cur)}  |  Fixed {_fmt(s.get('fixed_costs', 0), cur)}"),
            _kpi_card('Net Profit', _fmt(s.get('net_profit', 0), cur),
                      BRAND_GREEN if (s.get('net_profit', 0) or 0) >= 0 else BRAND_RED,
                      f"Margin {s.get('net_margin', 0)}%"),
            _kpi_card('Cash Collected', _fmt(s.get('cash_collected', 0), cur), BRAND_PURPLE,
                      f"AR {_fmt(s.get('outstanding', 0), cur)}"),
            _kpi_card('EBITDA', _fmt(s.get('ebitda', 0), cur), BRAND_BLUE,
                      f"Margin {s.get('ebitda_margin', 0)}%"),
            _kpi_card('Gross Profit', _fmt(s.get('gross_profit', 0), cur), BRAND_AMBER,
                      f"Margin {s.get('gross_margin', 0)}%"),
        ]

        # Build a 2×3 grid where each cell contains its card's inner paragraphs.
        # reportlab Table cells can hold a list of flowables.
        row1 = [kpi_cards[0], kpi_cards[1], kpi_cards[2]]
        row2 = [kpi_cards[3], kpi_cards[4], kpi_cards[5]]
        kpi_table = Table([row1, row2], colWidths=[col_w] * 3)
        kpi_table.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('TOPPADDING', (0, 0), (-1, -1), 12),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('LEFTPADDING', (0, 0), (-1, -1), 10),
            ('RIGHTPADDING', (0, 0), (-1, -1), 10),
            ('BACKGROUND', (0, 0), (-1, -1), BRAND_LIGHT),
            # Colored accent line at top of each card (top border per cell)
            ('LINEABOVE', (0, 0), (0, 0), 3, BRAND_GREEN),
            ('LINEABOVE', (1, 0), (1, 0), 3, BRAND_RED),
            ('LINEABOVE', (2, 0), (2, 0), 3,
                BRAND_GREEN if (s.get('net_profit', 0) or 0) >= 0 else BRAND_RED),
            ('LINEABOVE', (0, 1), (0, 1), 3, BRAND_PURPLE),
            ('LINEABOVE', (1, 1), (1, 1), 3, BRAND_BLUE),
            ('LINEABOVE', (2, 1), (2, 1), 3, BRAND_AMBER),
            # Thin grid lines between cards
            ('INNERGRID', (0, 0), (-1, -1), 3, colors.white),
            ('BOX', (0, 0), (-1, -1), 0.5, BRAND_LIGHT),
        ]))
        elements.append(kpi_table)

        # ── Side-by-side: Period-over-Period + Financial Ratios ──
        elements.append(Spacer(1, 18))

        # Left: Period-over-Period Changes
        def _change_cell(val):
            """Return a coloured Paragraph for a percentage change value."""
            v = float(val or 0)
            color = BRAND_GREEN if v > 0 else (BRAND_RED if v < 0 else BRAND_GREY)
            arrow = '▲ ' if v > 0 else ('▼ ' if v < 0 else '')
            return Paragraph(f'{arrow}{v}%', ParagraphStyle('chg', parent=style_normal,
                            fontSize=8, textColor=color, alignment=TA_RIGHT))

        trend_rows = [
            ['Metric', 'Current', 'Previous', 'Change'],
            ['Revenue', _fmt(s.get('revenue', 0), cur), _fmt(trends.get('prev_revenue', 0), cur),
             _change_cell(trends.get('revenue_change_pct', 0))],
            ['Operating Costs', _fmt(s.get('operating_costs', 0), cur), _fmt(trends.get('prev_costs', 0), cur),
             _change_cell(trends.get('cost_change_pct', 0))],
            ['Cash Collected', _fmt(s.get('cash_collected', 0), cur), _fmt(trends.get('prev_cash', 0), cur),
             _change_cell(trends.get('cash_change_pct', 0))],
        ]
        # Wrap text cells in Paragraphs to control font
        style_cell_l = ParagraphStyle('tcl', parent=style_normal, fontSize=8, textColor=BRAND_DARK)
        style_cell_r = ParagraphStyle('tcr', parent=style_normal, fontSize=8, textColor=BRAND_DARK, alignment=TA_RIGHT)
        trend_data = [trend_rows[0]]
        for row in trend_rows[1:]:
            trend_data.append([
                Paragraph(row[0], style_cell_l),
                Paragraph(row[1], style_cell_r),
                Paragraph(row[2], style_cell_r),
                row[3],
            ])

        trend_tbl = Table(trend_data, colWidths=[28 * mm, 28 * mm, 28 * mm, 20 * mm])
        trend_tbl.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), BRAND_INDIGO),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 8),
            ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
            ('ALIGN', (0, 1), (0, -1), 'LEFT'),
            ('ALIGN', (1, 1), (-1, -1), 'RIGHT'),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
            ('GRID', (0, 0), (-1, -1), 0.5, BRAND_LIGHT),
            ('TOPPADDING', (0, 0), (-1, -1), 5),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
            ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ]))

        # Right: Financial Ratios
        ratio_rows = [
            ['Ratio', 'Value', 'Note'],
            ['Current Ratio', str(s.get('current_ratio', 0)), 'Liquidity (>1 healthy)'],
            ['Quick Ratio', str(s.get('quick_ratio', 0)), 'Immediate liquidity'],
            ['DSO (days)', f"{s.get('dso', 0):.1f}" if isinstance(s.get('dso', 0), (int, float)) else str(s.get('dso', 0)),
             'Days Sales Outstanding'],
            ['Op. Leverage', f"{s.get('operating_leverage', 0)}x", 'Profit sensitivity'],
            ['ROA', f"{s.get('roa', 0)}%", 'Return on Assets'],
            ['Breakeven Rev.', _fmt(s.get('breakeven_revenue', 0), cur), 'Min. revenue needed'],
        ]
        ratio_data = [ratio_rows[0]]
        for row in ratio_rows[1:]:
            ratio_data.append([
                Paragraph(row[0], style_cell_l),
                Paragraph(row[1], style_cell_r),
                Paragraph(row[2], ParagraphStyle('rn', parent=style_normal, fontSize=7, textColor=BRAND_GREY)),
            ])

        ratio_tbl = Table(ratio_data, colWidths=[28 * mm, 25 * mm, 30 * mm])
        ratio_tbl.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), BRAND_INDIGO),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 8),
            ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
            ('ALIGN', (0, 1), (0, -1), 'LEFT'),
            ('ALIGN', (1, 1), (1, -1), 'RIGHT'),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
            ('GRID', (0, 0), (-1, -1), 0.5, BRAND_LIGHT),
            ('TOPPADDING', (0, 0), (-1, -1), 5),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
            ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ]))

        # Section headers above each table
        style_subhead = ParagraphStyle('subhead', parent=style_normal, fontSize=10,
                                       textColor=BRAND_INDIGO, fontName='Helvetica-Bold',
                                       spaceAfter=4)
        style_subhead_r = ParagraphStyle('subheadR', parent=style_subhead, alignment=TA_LEFT)

        # Wrap both tables in a 2-column layout
        left_block = [Paragraph('Period-over-Period', style_subhead_r), trend_tbl]
        right_block = [Paragraph('Financial Ratios', style_subhead_r), ratio_tbl]
        two_col = Table([[left_block, right_block]], colWidths=[col_w + 8 * mm, col_w + 8 * mm])
        two_col.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('LEFTPADDING', (0, 0), (-1, -1), 0),
            ('RIGHTPADDING', (0, 0), (-1, -1), 0),
            ('TOPPADDING', (0, 0), (-1, -1), 0),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
        ]))
        elements.append(two_col)

        # ── Revenue vs Costs comparison bar chart ──
        elements.append(Spacer(1, 16))
        rev_cost_data = [
            ('Revenue', float(s.get('revenue', 0) or 0)),
            ('OpEx', float(s.get('operating_costs', 0) or 0)),
            ('Fixed Costs', float(s.get('fixed_costs', 0) or 0)),
            ('Net Profit', float(s.get('net_profit', 0) or 0)),
        ]
        elements.append(_draw_bar('Revenue vs Costs Overview', rev_cost_data,
                                  width=160 * mm, height=55 * mm, color=BRAND_INDIGO))

    # ══════════════════════════════════════════════
    # PAGE 3 — Visual Analysis with real charts
    # ══════════════════════════════════════════════
    if 'revenue_charts' in sections:
        _start_content()
        elements.append(Paragraph('Visual Analysis', style_section))
        elements.append(Spacer(1, 6))

        # ── Revenue by Customer — Bar Chart + data table ──
        by_customer = revenue.get('by_customer', []) if revenue else []
        if by_customer:
            elements.append(Paragraph('Revenue by Customer (Top 10)', style_chart_title))
            elements.append(Spacer(1, 4))
            chart_data = [(c.get('customer', 'Unknown')[:15], float(c.get('revenue', 0) or 0))
                          for c in by_customer[:10]]
            elements.append(_draw_bar('Revenue by Customer', chart_data,
                                      width=150 * mm, height=70 * mm, color=BRAND_GREEN))
            elements.append(Spacer(1, 6))
            # Compact data table below chart
            cust_rows = [['Customer', 'Agreements', 'Revenue']]
            for c in by_customer[:10]:
                cust_rows.append([c.get('customer', ''), str(c.get('count', 0)), _fmt(c.get('revenue', 0), cur)])
            cust_tbl = Table(cust_rows, colWidths=[70 * mm, 30 * mm, 40 * mm])
            cust_tbl.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), BRAND_GREEN),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                ('FONTSIZE', (0, 0), (-1, -1), 7),
                ('GRID', (0, 0), (-1, -1), 0.5, BRAND_GREY),
                ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
                ('TOPPADDING', (0, 0), (-1, -1), 3),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
            ]))
            elements.append(cust_tbl)

        # ── Revenue Distribution Pie Chart ──
        if by_customer:
            elements.append(Spacer(1, 14))
            elements.append(Paragraph('Revenue Distribution by Customer', style_chart_title))
            elements.append(Spacer(1, 4))
            pie_data = [(c.get('customer', 'Unknown')[:15], float(c.get('revenue', 0) or 0))
                        for c in by_customer[:8] if float(c.get('revenue', 0) or 0) > 0]
            if pie_data:
                elements.append(_draw_pie('Revenue Distribution', pie_data,
                                          width=120 * mm, height=75 * mm))

        # ── Revenue by Vehicle — Horizontal Bar Chart + data table ──
        by_vehicle_rev = revenue.get('by_vehicle', []) if revenue else []
        if by_vehicle_rev:
            elements.append(Spacer(1, 12))
            elements.append(Paragraph('Revenue by Vehicle (Top 10)', style_chart_title))
            elements.append(Spacer(1, 4))
            chart_data = [(v.get('vehicle', 'Unknown')[:20], float(v.get('revenue', 0) or 0))
                          for v in by_vehicle_rev[:10]]
            elements.append(_draw_hbar('Revenue by Vehicle', chart_data,
                                       width=150 * mm, height=65 * mm, color=BRAND_BLUE))
            elements.append(Spacer(1, 6))
            vrows = [['Vehicle', 'Agreements', 'Revenue', 'Net']]
            for v in by_vehicle_rev[:10]:
                vrows.append([v.get('vehicle', ''), str(v.get('count', 0)),
                              _fmt(v.get('revenue', 0), cur), _fmt(v.get('net', 0), cur)])
            vtbl = Table(vrows, colWidths=[60 * mm, 25 * mm, 35 * mm, 35 * mm])
            vtbl.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), BRAND_BLUE),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                ('FONTSIZE', (0, 0), (-1, -1), 7),
                ('GRID', (0, 0), (-1, -1), 0.5, BRAND_GREY),
                ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
                ('TOPPADDING', (0, 0), (-1, -1), 3),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
            ]))
            elements.append(vtbl)

        # ── Revenue Trend — Line/Area Chart + compact table (filter zero rows) ──
        trend = revenue.get('trend', []) if revenue else []
        trend_filtered = [t for t in trend if (t.get('revenue', 0) or 0) > 0 or (t.get('payments', 0) or 0) > 0]
        if trend_filtered:
            elements.append(Spacer(1, 14))
            elements.append(Paragraph('Revenue Trend', style_chart_title))
            elements.append(Spacer(1, 4))
            elements.append(_draw_line_area(
                'Revenue and Payments Trend', trend_filtered,
                series_labels=['Revenue', 'Payments'],
                width=150 * mm, height=70 * mm,
                series_colors=[BRAND_GREEN, BRAND_BLUE],
            ))
            elements.append(Spacer(1, 6))
            trows = [['Date', 'Revenue', 'Payments']]
            for t in trend_filtered:
                trows.append([t.get('date', ''), _fmt(t.get('revenue', 0), cur), _fmt(t.get('payments', 0), cur)])
            ttbl = Table(trows, colWidths=[40 * mm, 50 * mm, 50 * mm])
            ttbl.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), BRAND_PURPLE),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                ('FONTSIZE', (0, 0), (-1, -1), 7),
                ('GRID', (0, 0), (-1, -1), 0.5, BRAND_GREY),
                ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
                ('TOPPADDING', (0, 0), (-1, -1), 3),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
            ]))
            elements.append(ttbl)

        # ── Cost Breakdown — Pie Chart + data table ──
    if 'cost_analysis' in sections:
        _start_content()
        elements.append(Paragraph('Cost Analysis', style_section))
        elements.append(Spacer(1, 6))

        by_category = costs.get('by_category', []) if costs else []
        if by_category:
            elements.append(Paragraph('Cost Breakdown by Category', style_chart_title))
            elements.append(Spacer(1, 4))
            pie_data = [(c.get('category', 'Unknown'), float(c.get('amount', 0) or 0))
                        for c in by_category if float(c.get('amount', 0) or 0) > 0]
            if pie_data:
                elements.append(_draw_pie('Cost by Category', pie_data,
                                          width=120 * mm, height=80 * mm))
            elements.append(Spacer(1, 6))
            crows = [['Category', 'Type', 'Amount']]
            for c in by_category:
                crows.append([c.get('category', ''), c.get('type', ''), _fmt(c.get('amount', 0), cur)])
            ctot = costs.get('total', 0) if costs else 0
            crows.append(['TOTAL', '', _fmt(ctot, cur)])
            ctbl = Table(crows, colWidths=[80 * mm, 25 * mm, 40 * mm])
            ctbl.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), BRAND_RED),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                ('FONTSIZE', (0, 0), (-1, -1), 7),
                ('GRID', (0, 0), (-1, -1), 0.5, BRAND_GREY),
                ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
                ('ROWBACKGROUNDS', (0, 1), (-1, -2), [colors.white, BRAND_LIGHT]),
                ('BACKGROUND', (0, -1), (-1, -1), BRAND_LIGHT),
                ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
                ('TOPPADDING', (0, 0), (-1, -1), 3),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
            ]))
            elements.append(ctbl)

        # Cost by vehicle — Bar Chart + data table
        by_vehicle_cost = costs.get('by_vehicle', []) if costs else []
        if by_vehicle_cost:
            elements.append(Spacer(1, 14))
            elements.append(Paragraph('Cost Breakdown by Vehicle', style_chart_title))
            elements.append(Spacer(1, 4))
            chart_data = [(v.get('vehicle', 'Unknown')[:15], float(v.get('total_cost', 0) or 0))
                          for v in by_vehicle_cost[:10]]
            if chart_data:
                elements.append(_draw_bar('Total Cost by Vehicle', chart_data,
                                          width=150 * mm, height=65 * mm, color=BRAND_AMBER))
            elements.append(Spacer(1, 6))
            vcrows = [['Vehicle', 'Fuel', 'Charging', 'Service', 'Fixed', 'Total']]
            for v in by_vehicle_cost[:15]:
                vcrows.append([
                    v.get('vehicle', ''),
                    _fmt(v.get('fuel_cost', 0), cur),
                    _fmt(v.get('charging_cost', 0), cur),
                    _fmt(v.get('service_cost', 0), cur),
                    _fmt(v.get('fixed_cost', 0), cur),
                    _fmt(v.get('total_cost', 0), cur),
                ])
            vctbl = Table(vcrows, colWidths=[45 * mm, 22 * mm, 22 * mm, 22 * mm, 22 * mm, 25 * mm])
            vctbl.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), BRAND_AMBER),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                ('FONTSIZE', (0, 0), (-1, -1), 7),
                ('GRID', (0, 0), (-1, -1), 0.5, BRAND_GREY),
                ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
                ('TOPPADDING', (0, 0), (-1, -1), 3),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
            ]))
            elements.append(vctbl)

        # ── P&L Statement ──
    if 'profit_loss' in sections:
        _start_content()
        elements.append(Paragraph('Profit and Loss Statement', style_section))
        elements.append(Spacer(1, 8))

        pnl_rows = [
            ['Item', 'Amount'],
            ['Revenue (Rental)', _fmt(s.get('revenue', 0), cur)],
            ['', ''],
            ['Operating Costs', ''],
            ['  Fuel & Charging', _fmt(s.get('operating_costs', 0) * 0.4, cur)],
            ['  Service & Maintenance', _fmt(s.get('operating_costs', 0) * 0.3, cur)],
            ['  Other OpEx', _fmt(s.get('operating_costs', 0) * 0.3, cur)],
            ['  Total Operating Costs', _fmt(s.get('operating_costs', 0), cur)],
            ['', ''],
            ['Fixed Costs', ''],
            ['  Lease Payments', ''],
            ['  Insurance', ''],
            ['  Financing', ''],
            ['  Depreciation', ''],
            ['  Total Fixed Costs', _fmt(s.get('fixed_costs', 0), cur)],
            ['', ''],
            ['Total Costs', _fmt(s.get('total_costs', 0), cur)],
            ['Gross Profit', _fmt(s.get('gross_profit', 0), cur)],
            ['Net Profit', _fmt(s.get('net_profit', 0), cur)],
            ['', ''],
            ['Gross Margin (%)', f"{s.get('gross_margin', 0)}%"],
            ['Net Margin (%)', f"{s.get('net_margin', 0)}%"],
            ['EBITDA', _fmt(s.get('ebitda', 0), cur)],
            ['EBITDA Margin (%)', f"{s.get('ebitda_margin', 0)}%"],
        ]
        pnl_tbl = Table(pnl_rows, colWidths=[90 * mm, 50 * mm])
        pnl_tbl.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), BRAND_INDIGO),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('GRID', (0, 0), (-1, -1), 0.5, BRAND_GREY),
            ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
            ('FONTNAME', (0, -4), (-1, -4), 'Helvetica-Bold'),
            ('FONTNAME', (0, -3), (-1, -3), 'Helvetica-Bold'),
            ('FONTNAME', (0, -7), (-1, -7), 'Helvetica-Bold'),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))
        elements.append(pnl_tbl)

        # ── Vehicle ROI ──
    if 'vehicle_roi' in sections:
        _start_content()
        elements.append(Paragraph('Vehicle ROI Analysis', style_section))
        elements.append(Spacer(1, 8))

        if roi_data:
            roi_rows = [['#', 'Vehicle', 'Agreements', 'Revenue', 'Fuel', 'Service', 'Fixed', 'Total Cost', 'Net Profit', 'ROI %']]
            for i, v in enumerate(roi_data, 1):
                roi_rows.append([
                    str(i),
                    v.get('vehicle', ''),
                    str(v.get('agreement_count', 0)),
                    _fmt(v.get('revenue', 0), cur),
                    _fmt(v.get('fuel_cost', 0), cur),
                    _fmt(v.get('service_cost', 0), cur),
                    _fmt(v.get('fixed_cost', 0), cur),
                    _fmt(v.get('total_cost', 0), cur),
                    _fmt(v.get('net_profit', 0), cur),
                    f"{v.get('roi_pct', 0)}%",
                ])
            roi_tbl = Table(roi_rows, colWidths=[10*mm, 35*mm, 18*mm, 22*mm, 18*mm, 18*mm, 18*mm, 22*mm, 22*mm, 15*mm])
            roi_tbl.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), BRAND_INDIGO),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                ('FONTSIZE', (0, 0), (-1, 0), 8),
                ('FONTSIZE', (0, 1), (-1, -1), 7),
                ('GRID', (0, 0), (-1, -1), 0.5, BRAND_GREY),
                ('ALIGN', (2, 0), (-1, -1), 'RIGHT'),
                ('ALIGN', (0, 0), (0, -1), 'CENTER'),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
                ('TOPPADDING', (0, 0), (-1, -1), 4),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ]))
            elements.append(roi_tbl)

            # ROI summary
            total_rev = sum(float(v.get('revenue', 0)) for v in roi_data)
            total_cost = sum(float(v.get('total_cost', 0)) for v in roi_data)
            total_net = sum(float(v.get('net_profit', 0)) for v in roi_data)
            fleet_roi = round(total_net / total_cost * 100, 1) if total_cost else 0
            elements.append(Spacer(1, 10))
            elements.append(Paragraph(
                f'<b>Fleet ROI:</b> {fleet_roi}%  ·  '
                f'<b>Total Revenue:</b> {_fmt(total_rev, cur)}  ·  '
                f'<b>Total Cost:</b> {_fmt(total_cost, cur)}  ·  '
                f'<b>Net Profit:</b> {_fmt(total_net, cur)}',
                style_normal
            ))

    # Build doc
    doc.build(elements)

    output.seek(0)
    response = HttpResponse(content_type='application/pdf')
    filename = f'financial_report_{datetime.now().strftime("%Y%m%d")}.pdf'
    response['Content-Disposition'] = f'attachment; filename="{filename}"'
    response.write(output.getvalue())
    return response
