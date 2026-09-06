"""Vehicle Fuel Details PDF generator using reportlab.

Generates a multi-page PDF with:
- Vehicle information header
- Fuel summary KPIs
- Cost trend line+area chart
- Fuel type breakdown
- Full transaction table
"""

import io
from datetime import datetime

from django.http import HttpResponse
from reportlab.lib import colors
from reportlab.lib.utils import ImageReader
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.graphics.shapes import Drawing, String
from reportlab.graphics.charts.lineplots import LinePlot
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    PageBreak,
)
from reportlab.platypus.flowables import HRFlowable

# Brand colors (matching the existing pdf_report.py palette)
BRAND_INDIGO = colors.HexColor('#4f46e5')
BRAND_DARK   = colors.HexColor('#1e293b')
BRAND_GREY   = colors.HexColor('#64748b')
BRAND_GREEN  = colors.HexColor('#166534')
BRAND_RED    = colors.HexColor('#991b1b')
BRAND_AMBER  = colors.HexColor('#d97706')
BRAND_LIGHT  = colors.HexColor('#f1f5f9')
PIE_COLORS = [
    colors.HexColor('#6366f1'), colors.HexColor('#f59e0b'), colors.HexColor('#10b981'),
    colors.HexColor('#ef4444'), colors.HexColor('#3b82f6'), colors.HexColor('#ec4899'),
    colors.HexColor('#8b5cf6'), colors.HexColor('#64748b'),
]


def _fmt(n, cur=''):
    try:
        n = float(n)
    except (TypeError, ValueError):
        n = 0.0
    if n < 0:
        return f'-{cur}{abs(n):,.2f}'
    return f'{cur}{n:,.2f}'


def _fmt_int(n):
    try:
        n = int(float(n))
    except (TypeError, ValueError):
        return '—'
    return f'{n:,}'


def _draw_line_area(title, labels, values, width=420, height=260):
    """Draw a styled line+area chart for the cost trend.

    width/height define the inner chart plotting area; the outer Drawing
    adds room for the title bar, axis labels, and margins.
    Usable A4 width with 18mm margins ≈ 493pt, so total Drawing ≤ ~490pt.
    """
    pad_left = 50
    pad_right = 15
    pad_top = 34
    pad_bottom = 28
    outer_w = width + pad_left + pad_right
    outer_h = height + pad_top + pad_bottom

    d = Drawing(outer_w, outer_h)

    # Background card
    from reportlab.graphics.shapes import Rect
    card = Rect(0, 0, outer_w, outer_h,
                fillColor=colors.HexColor('#fafbff'),
                strokeColor=colors.HexColor('#e2e8f0'), strokeWidth=0.5, rx=8, ry=8)
    d.add(card)

    if not values:
        d.add(String(outer_w / 2, outer_h / 2, 'No data available',
                     textAnchor='middle', fontName='Helvetica', fontSize=11,
                     fillColor=BRAND_GREY))
        return d

    # Title bar
    title_bar = Rect(8, outer_h - pad_top + 6, outer_w - 16, 22,
                     fillColor=BRAND_INDIGO, strokeColor=None, rx=4, ry=4)
    d.add(title_bar)
    d.add(String(outer_w / 2, outer_h - pad_top + 14, title, textAnchor='middle',
                 fontName='Helvetica-Bold', fontSize=11, fillColor=colors.white))

    lp = LinePlot()
    lp.x = pad_left
    lp.y = pad_bottom
    lp.width = width
    lp.height = height

    n = len(values)
    data = [[(i, float(values[i])) for i in range(n)]]
    lp.data = data
    lp.joinedLines = True
    lp.lines[0].strokeColor = BRAND_INDIGO
    lp.lines[0].strokeWidth = 2.5
    lp.lines[0].strokeDashArray = None

    # Y axis
    lp.yValueAxis.valueMin = 0
    max_val = max(values) if values else 1
    lp.yValueAxis.valueMax = max_val * 1.2 if max_val > 0 else 1
    lp.yValueAxis.valueStep = max_val / 5 if max_val > 0 else 1
    lp.yValueAxis.labels.fontName = 'Helvetica'
    lp.yValueAxis.labels.fontSize = 7
    lp.yValueAxis.labels.fillColor = BRAND_GREY
    lp.yValueAxis.strokeColor = colors.HexColor('#cbd5e1')
    lp.yValueAxis.visibleGrid = True
    lp.yValueAxis.gridStrokeColor = colors.HexColor('#e8eaf0')
    lp.yValueAxis.gridStrokeWidth = 0.5

    # X axis — hide numeric labels, we'll draw date strings manually
    lp.xValueAxis.valueMin = 0
    lp.xValueAxis.valueMax = max(n - 1, 1)
    lp.xValueAxis.labels.fontSize = 0  # hide default numeric labels
    lp.xValueAxis.strokeColor = colors.HexColor('#cbd5e1')
    lp.xValueAxis.visibleGrid = True
    lp.xValueAxis.gridStrokeColor = colors.HexColor('#e8eaf0')
    lp.xValueAxis.gridStrokeWidth = 0.5

    # Compute pixel coords for data points
    x_max = max(n - 1, 1)
    y_max = lp.yValueAxis.valueMax
    y_min = lp.yValueAxis.valueMin
    points = []
    for i in range(n):
        px = pad_left + (i / x_max) * width if x_max > 0 else pad_left
        py = pad_bottom + ((float(values[i]) - y_min) / (y_max - y_min)) * height if y_max > y_min else pad_bottom
        points.append((px, py))

    # Draw gradient area fill under the line using stacked bands (lighter at bottom)
    # reportlab Graphics don't support gradient fills, so we simulate with
    # multiple semi-transparent horizontal bands from base to the line
    from reportlab.graphics.shapes import Polygon, Group
    if n >= 2:
        # Build the area polygon: line points left-to-right, then baseline right-to-left
        area_path = [(points[0][0], pad_bottom)]  # start at bottom-left
        area_path.extend(points)                  # along the line
        area_path.append((points[-1][0], pad_bottom))  # down to bottom-right

        # Draw 3 stacked layers for a gradient-like effect (dark on top → light at bottom)
        for layer, (frac, alpha) in enumerate([(1.0, 0.22), (0.66, 0.14), (0.33, 0.08)]):
            band_path = []
            for px, py in points:
                band_y = pad_bottom + (py - pad_bottom) * frac
                band_path.append(px)
                band_path.append(band_y)
            # Close the polygon: start at bottom-left, line points, end at bottom-right
            flat_points = [band_path[0], pad_bottom] + band_path + [band_path[-2], pad_bottom]
            band_color = colors.HexColor('#818cf8')  # lighter indigo
            poly = Polygon(flat_points, fillColor=band_color, strokeColor=None,
                           fillOpacity=alpha)
            d.add(poly)

    d.add(lp)

    # Manually draw date labels along the X axis
    # Decide how many labels to show (max ~8 to avoid crowding)
    max_labels = 8
    label_step = max(1, n // max_labels)
    for i in range(0, n, label_step):
        px = pad_left + (i / x_max) * width if x_max > 0 else pad_left
        lbl = labels[i] if i < len(labels) else ''
        d.add(String(px, pad_bottom - 14, lbl,
                     textAnchor='middle', fontName='Helvetica', fontSize=7,
                     fillColor=BRAND_GREY))
    # Always show the last label
    if (n - 1) % label_step != 0 and n > 0:
        px = pad_left + width
        lbl = labels[n - 1] if n - 1 < len(labels) else ''
        d.add(String(px, pad_bottom - 14, lbl,
                     textAnchor='middle', fontName='Helvetica', fontSize=7,
                     fillColor=BRAND_GREY))

    # Data point markers
    from reportlab.graphics.shapes import Circle as RLCircle
    y_max = lp.yValueAxis.valueMax
    y_min = lp.yValueAxis.valueMin
    for i in range(n):
        px = pad_left + (i / x_max) * width if x_max > 0 else pad_left
        py = pad_bottom + ((float(values[i]) - y_min) / (y_max - y_min)) * height if y_max > y_min else pad_bottom
        d.add(RLCircle(px, py, 2.5, fillColor=BRAND_INDIGO,
                       strokeColor=colors.white, strokeWidth=1))

    return d


def _cur_label(tenant):
    cmap = {
        'USD': '$', 'EUR': '€', 'GBP': '£', 'KES': 'KSh', 'NGN': '₦',
        'ZAR': 'R', 'AED': 'AED', 'SAR': 'SAR', 'INR': '₹', 'CAD': 'C$',
        'AUD': 'A$', 'JPY': '¥', 'CNY': '¥', 'GHS': '₵',
        'TZS': 'TSh', 'UGX': 'USh', 'RWF': 'FRw', 'ETB': 'Br',
    }
    return cmap.get(getattr(tenant, 'currency', 'USD'), '$')


def _build_business_header(tenant):
    """Build a flowable table with the tenant's logo, name, phone, and address."""
    biz_name_style = ParagraphStyle('BizName', fontName='Helvetica-Bold',
                                   fontSize=16, textColor=BRAND_DARK, leading=20)
    biz_info_style = ParagraphStyle('BizInfo', fontName='Helvetica',
                                    fontSize=9, textColor=BRAND_GREY, leading=13)

    biz_name = getattr(tenant, 'full_name', '') or getattr(tenant, 'short_name', '') or 'Business'
    phone = getattr(tenant, 'mobile_number', '') or ''
    address = getattr(tenant, 'address', '') or ''
    country = getattr(tenant, 'country', '') or ''
    email = getattr(tenant, 'email', '') or ''

    # Build info lines
    info_lines = []
    if phone:
        info_lines.append(f'Tel: {phone}')
    if address or country:
        loc_parts = []
        if address:
            loc_parts.append(address)
        if country and country.lower() not in address.lower():
            loc_parts.append(country)
        info_lines.append('Location: ' + ', '.join(loc_parts))
    if email:
        info_lines.append(f'Email: {email}')
    info_text = '<br/>'.join(info_lines) if info_lines else ''

    # Try to load the logo
    logo_flowable = None
    if getattr(tenant, 'logo', None) and tenant.logo:
        try:
            tenant.logo.open('rb')
            try:
                img_bytes = tenant.logo.read()
            finally:
                tenant.logo.close()
            img = ImageReader(io.BytesIO(img_bytes))
            img_w, img_h = img.getSize()
            max_box = 60
            scale = min(max_box / img_w, max_box / img_h)
            draw_w = img_w * scale
            draw_h = img_h * scale
            from reportlab.platypus import Image as RLImage
            logo_flowable = RLImage(io.BytesIO(img_bytes), width=draw_w, height=draw_h)
        except Exception:
            logo_flowable = None

    if logo_flowable:
        header_data = [[logo_flowable, Paragraph(biz_name, biz_name_style)]]
        header = Table(header_data, colWidths=[70 * mm, 104 * mm])
        header.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('LEFTPADDING', (0, 0), (0, 0), 0),
            ('RIGHTPADDING', (0, 0), (0, 0), 12),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))
    else:
        header_data = [[Paragraph(biz_name, biz_name_style)]]
        header = Table(header_data, colWidths=[174 * mm])
        header.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))

    # Build the info row below the name/logo
    if info_text:
        info_data = [[Paragraph(info_text, biz_info_style)]]
        info_table = Table(info_data, colWidths=[174 * mm])
        info_table.setStyle(TableStyle([
            ('LEFTPADDING', (0, 0), (-1, -1), 0),
            ('TOPPADDING', (0, 0), (-1, -1), 2),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
        ]))
        return [header, info_table]
    return [header]


def generate_vehicle_fuel_pdf(vehicle, transactions, currency='$', tenant=None, period_str=''):
    """Generate a PDF for vehicle fuel details.

    Args:
        vehicle: Vehicle model instance
        transactions: list of FuelTransaction instances (ordered by date)
        currency: currency symbol string
        tenant: optional Tenant model instance for business header
        period_str: optional human-readable date range string (e.g. "Period: Jan 01 — Dec 31")

    Returns:
        HttpResponse with PDF content
    """
    buf = io.BytesIO()
    doc = SimpleDocTemplate(
        buf,
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=15 * mm,
        bottomMargin=15 * mm,
        title=f'Fuel Report - {vehicle.display_name}',
    )

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle('CustomTitle', parent=styles['Heading1'],
                                 fontSize=18, textColor=BRAND_INDIGO, spaceAfter=4)
    subtitle_style = ParagraphStyle('CustomSubtitle', parent=styles['Normal'],
                                    fontSize=10, textColor=BRAND_GREY, spaceAfter=10)
    section_style = ParagraphStyle('Section', parent=styles['Heading2'],
                                   fontSize=13, textColor=BRAND_DARK,
                                   spaceBefore=14, spaceAfter=6)
    cell_style = ParagraphStyle('Cell', parent=styles['Normal'],
                                fontSize=8, textColor=BRAND_DARK)
    cell_header_style = ParagraphStyle('CellHeader', parent=styles['Normal'],
                                       fontSize=8, textColor=colors.white,
                                       fontName='Helvetica-Bold')
    small_style = ParagraphStyle('Small', parent=styles['Normal'],
                                 fontSize=9, textColor=BRAND_DARK, leading=14)
    kpi_value_style = ParagraphStyle('KPIValue', parent=styles['Normal'],
                                     fontSize=16, textColor=BRAND_INDIGO,
                                     fontName='Helvetica-Bold', alignment=TA_CENTER)
    kpi_label_style = ParagraphStyle('KPILabel', parent=styles['Normal'],
                                     fontSize=8, textColor=BRAND_GREY,
                                     alignment=TA_CENTER, spaceAfter=2)

    story = []

    # ─── Business Header (logo, name, phone, location) ───
    if tenant:
        business_header = _build_business_header(tenant)
        for flowable in business_header:
            story.append(flowable)
        story.append(Spacer(1, 6))

    # ─── Title ───
    story.append(Paragraph('Vehicle Fuel Report', title_style))
    story.append(Paragraph(
        f'{vehicle.display_name} &nbsp;·&nbsp; {vehicle.license_plate or "—"} &nbsp;·&nbsp; VIN: {vehicle.vin or "—"} &nbsp;·&nbsp; Generated: {datetime.now().strftime("%Y-%m-%d %H:%M")}',
        subtitle_style,
    ))
    if period_str:
        period_style = ParagraphStyle('Period', parent=styles['Normal'],
                                      fontSize=10, textColor=BRAND_INDIGO,
                                      fontName='Helvetica-Bold', spaceAfter=6)
        story.append(Paragraph(period_str, period_style))
    story.append(HRFlowable(width='100%', thickness=1.5, color=BRAND_INDIGO))
    story.append(Spacer(1, 12))

    # ─── Vehicle Info ───
    story.append(Paragraph('Vehicle Information', section_style))
    vinfo = [
        ['Make', vehicle.make or '—', 'Model', vehicle.model or '—'],
        ['Year', str(vehicle.year or '—'), 'Fuel Type', vehicle.fuel_type or '—'],
        ['Status', vehicle.status.replace('_', ' ').title() if vehicle.status else '—', 'Mileage', f'{_fmt_int(vehicle.current_mileage)} {vehicle.mileage_unit}'],
        ['Color', vehicle.color or '—', 'Location', vehicle.location or '—'],
    ]
    vtable = Table(vinfo, colWidths=[28*mm, 55*mm, 28*mm, 63*mm])
    vtable.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTNAME', (2, 0), (2, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('TEXTCOLOR', (0, 0), (0, -1), BRAND_GREY),
        ('TEXTCOLOR', (2, 0), (2, -1), BRAND_GREY),
        ('TEXTCOLOR', (1, 0), (1, -1), BRAND_DARK),
        ('TEXTCOLOR', (3, 0), (3, -1), BRAND_DARK),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('BACKGROUND', (0, 0), (0, -1), BRAND_LIGHT),
        ('BACKGROUND', (2, 0), (2, -1), BRAND_LIGHT),
        ('BOX', (0, 0), (-1, -1), 0.5, BRAND_GREY),
        ('LINEBELOW', (0, 0), (-1, -2), 0.3, colors.HexColor('#e2e8f0')),
    ]))
    story.append(vtable)
    story.append(Spacer(1, 16))

    # ─── Compute summary ───
    txs = list(transactions)
    txs.sort(key=lambda t: t.date)
    fill_count = len(txs)
    total_cost = sum(float(t.total_cost or 0) for t in txs)
    total_volume = sum(float(t.quantity or 0) for t in txs)
    avg_price = total_cost / total_volume if total_volume else 0
    odometers = [float(t.odometer_reading) for t in txs if t.odometer_reading is not None]
    min_odo = min(odometers) if odometers else None
    max_odo = max(odometers) if odometers else None
    distance = (max_odo - min_odo) if (min_odo is not None and max_odo is not None) else None
    avg_mpg = (distance / total_volume) if (distance and total_volume) else None
    unit_label = 'L' if (txs[0].unit == 'liters' if txs else False) else 'gal'
    dist_label = 'km' if (txs[0].unit == 'liters' if txs else False) else 'mi'

    # ─── Summary KPIs ───
    story.append(Paragraph('Fuel Summary', section_style))
    kpi_data = [
        [Paragraph('Fill-ups', kpi_label_style),
         Paragraph('Total Volume', kpi_label_style),
         Paragraph('Total Cost', kpi_label_style),
         Paragraph('Avg Price/Unit', kpi_label_style)],
        [Paragraph(str(fill_count), kpi_value_style),
         Paragraph(f'{total_volume:,.1f} {unit_label}', kpi_value_style),
         Paragraph(f'{currency}{total_cost:,.2f}', kpi_value_style),
         Paragraph(f'{currency}{avg_price:,.3f}', kpi_value_style)],
    ]
    kpi_table = Table(kpi_data, colWidths=[42*mm]*4)
    kpi_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), BRAND_LIGHT),
        ('BACKGROUND', (0, 1), (-1, 1), colors.white),
        ('BOX', (0, 0), (-1, -1), 0.5, BRAND_GREY),
        ('INNERGRID', (0, 0), (-1, -1), 0.3, colors.HexColor('#e2e8f0')),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, 0), 6),
        ('BOTTOMPADDING', (0, 1), (-1, 1), 10),
        ('TOPPADDING', (0, 1), (-1, 1), 6),
    ]))
    story.append(kpi_table)
    story.append(Spacer(1, 10))

    # Distance & Efficiency sub-row
    dist_data = [
        ['Distance Travelled' , 'Avg Efficiency', 'Min Odometer', 'Max Odometer'],
        [
            f'{_fmt_int(distance)} {dist_label}' if distance else '—',
            f'{avg_mpg:.1f} {dist_label}/{unit_label}' if avg_mpg else '—',
            f'{_fmt_int(min_odo)} {dist_label}' if min_odo else '—',
            f'{_fmt_int(max_odo)} {dist_label}' if max_odo else '—',
        ],
    ]
    dist_table = Table(dist_data, colWidths=[42*mm]*4)
    dist_table.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 8),
        ('FONTSIZE', (0, 1), (-1, 1), 10),
        ('TEXTCOLOR', (0, 0), (-1, 0), BRAND_GREY),
        ('TEXTCOLOR', (0, 1), (-1, 1), BRAND_DARK),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('BACKGROUND', (0, 0), (-1, 0), BRAND_LIGHT),
        ('BOX', (0, 0), (-1, -1), 0.5, BRAND_GREY),
        ('INNERGRID', (0, 0), (-1, -1), 0.3, colors.HexColor('#e2e8f0')),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
    ]))
    story.append(dist_table)
    story.append(Spacer(1, 16))

    # ─── Cost Trend Chart ───
    story.append(Paragraph('Fuel Cost Trend', section_style))
    chart_labels = [t.date.strftime('%b %d') for t in txs]
    chart_values = [float(t.total_cost or 0) for t in txs]
    chart = _draw_line_area('Cost per Fill-up', chart_labels, chart_values)
    story.append(chart)
    story.append(Spacer(1, 16))

    # ─── Full Transaction Table ───
    story.append(Paragraph('All Fuel Transactions', section_style))

    header = [
        Paragraph('#', cell_header_style),
        Paragraph('Date', cell_header_style),
        Paragraph('Fuel Type', cell_header_style),
        Paragraph('Quantity', cell_header_style),
        Paragraph('Cost', cell_header_style),
        Paragraph('Price/Unit', cell_header_style),
        Paragraph('Odometer', cell_header_style),
        Paragraph('MPG', cell_header_style),
        Paragraph('Station', cell_header_style),
        Paragraph('Location', cell_header_style),
    ]
    table_data = [header]
    for i, t in enumerate(txs, 1):
        mpg_val = f'{t.mpg:.1f}' if t.mpg else '—'
        table_data.append([
            Paragraph(str(i), cell_style),
            Paragraph(t.date.strftime('%Y-%m-%d %H:%M'), cell_style),
            Paragraph(t.fuel_type or '—', cell_style),
            Paragraph(f'{float(t.quantity or 0):,.2f} {unit_label}', cell_style),
            Paragraph(f'{currency}{float(t.total_cost or 0):,.2f}', cell_style),
            Paragraph(f'{currency}{t.price_per_unit:.3f}' if t.price_per_unit else '—', cell_style),
            Paragraph(_fmt_int(t.odometer_reading), cell_style),
            Paragraph(mpg_val, cell_style),
            Paragraph(t.station_name or '—', cell_style),
            Paragraph(t.station_location or '—', cell_style),
        ])

    tx_table = Table(table_data, colWidths=[
        8*mm, 22*mm, 18*mm, 16*mm, 18*mm, 14*mm, 16*mm, 12*mm, 22*mm, 24*mm,
    ], repeatRows=1)
    tx_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), BRAND_INDIGO),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
        ('GRID', (0, 0), (-1, -1), 0.3, colors.HexColor('#e2e8f0')),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 3),
        ('RIGHTPADDING', (0, 0), (-1, -1), 3),
    ]))
    story.append(tx_table)

    # ─── Footer ───
    story.append(Spacer(1, 20))
    story.append(HRFlowable(width='100%', thickness=0.5, color=BRAND_GREY))
    story.append(Spacer(1, 4))
    story.append(Paragraph(
        f'Generated by DomendraFleet on {datetime.now().strftime("%Y-%m-%d at %H:%M")} '
        f'· {fill_count} transactions · Total: {currency}{total_cost:,.2f}',
        ParagraphStyle('Footer', parent=styles['Normal'], fontSize=8,
                       textColor=BRAND_GREY, alignment=TA_CENTER),
    ))

    doc.build(story)
    buf.seek(0)

    response = HttpResponse(buf, content_type='application/pdf')
    filename = f'fuel-report-{vehicle.make}-{vehicle.model}-{datetime.now().strftime("%Y%m%d")}.pdf'
    response['Content-Disposition'] = f'attachment; filename="{filename}"'
    return response


def generate_fleet_fuel_pdf(analytics_data, currency='$', tenant=None, period_str=''):
    """Generate a PDF report for all vehicles' fuel analytics.

    Args:
        analytics_data: dict with the analytics response (by_vehicle, total_cost,
                        daily_trend, by_fuel_type, by_station, etc.)
        currency: currency symbol string
        tenant: optional Tenant model instance for business header
        period_str: optional human-readable date range string

    Returns:
        HttpResponse with PDF content
    """
    buf = io.BytesIO()
    doc = SimpleDocTemplate(
        buf,
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=15 * mm,
        bottomMargin=15 * mm,
        title='Fleet Fuel Report',
    )

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle('FleetTitle', parent=styles['Heading1'],
                                 fontSize=18, textColor=BRAND_INDIGO, spaceAfter=4)
    subtitle_style = ParagraphStyle('FleetSub', parent=styles['Normal'],
                                    fontSize=10, textColor=BRAND_GREY, spaceAfter=10)
    section_style = ParagraphStyle('FleetSection', parent=styles['Heading2'],
                                  fontSize=13, textColor=BRAND_DARK,
                                  spaceBefore=14, spaceAfter=6)
    cell_style = ParagraphStyle('FleetCell', parent=styles['Normal'],
                                fontSize=8, textColor=BRAND_DARK)
    cell_header_style = ParagraphStyle('FleetCellH', parent=styles['Normal'],
                                        fontSize=8, textColor=colors.white,
                                        fontName='Helvetica-Bold')
    kpi_value_style = ParagraphStyle('FleetKPI', parent=styles['Normal'],
                                     fontSize=16, textColor=BRAND_INDIGO,
                                     fontName='Helvetica-Bold', alignment=TA_CENTER)
    kpi_label_style = ParagraphStyle('FleetKPILbl', parent=styles['Normal'],
                                     fontSize=8, textColor=BRAND_GREY,
                                     alignment=TA_CENTER, spaceAfter=2)

    story = []

    # ─── Business Header ───
    if tenant:
        business_header = _build_business_header(tenant)
        for flowable in business_header:
            story.append(flowable)
        story.append(Spacer(1, 6))

    # ─── Title ───
    story.append(Paragraph('Fleet Fuel Analytics Report', title_style))
    story.append(Paragraph(
        f'Generated: {datetime.now().strftime("%Y-%m-%d %H:%M")}',
        subtitle_style,
    ))
    if period_str:
        period_style = ParagraphStyle('FleetPeriod', parent=styles['Normal'],
                                      fontSize=10, textColor=BRAND_INDIGO,
                                      fontName='Helvetica-Bold', spaceAfter=6)
        story.append(Paragraph(period_str, period_style))
    story.append(HRFlowable(width='100%', thickness=1.5, color=BRAND_INDIGO))
    story.append(Spacer(1, 12))

    # ─── Summary KPIs ───
    total_cost = float(analytics_data.get('total_cost', 0))
    total_gallons = float(analytics_data.get('total_gallons', 0))
    tx_count = analytics_data.get('transaction_count', 0)
    avg_price_gal = float(analytics_data.get('avg_price_per_gallon', 0))
    max_tx = float(analytics_data.get('max_transaction_cost', 0))
    min_tx = float(analytics_data.get('min_transaction_cost', 0))

    story.append(Paragraph('Fleet Summary', section_style))
    kpi_data = [
        [Paragraph('Transactions', kpi_label_style),
         Paragraph('Total Volume', kpi_label_style),
         Paragraph('Total Cost', kpi_label_style),
         Paragraph('Avg Price/Unit', kpi_label_style)],
        [Paragraph(str(tx_count), kpi_value_style),
         Paragraph(f'{total_gallons:,.1f} gal', kpi_value_style),
         Paragraph(f'{currency}{total_cost:,.2f}', kpi_value_style),
         Paragraph(f'{currency}{avg_price_gal:,.3f}', kpi_value_style)],
    ]
    kpi_table = Table(kpi_data, colWidths=[42*mm]*4)
    kpi_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), BRAND_LIGHT),
        ('BOX', (0, 0), (-1, -1), 0.5, BRAND_GREY),
        ('INNERGRID', (0, 0), (-1, -1), 0.3, colors.HexColor('#e2e8f0')),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, 0), 6),
        ('BOTTOMPADDING', (0, 1), (-1, 1), 10),
        ('TOPPADDING', (0, 1), (-1, 1), 6),
    ]))
    story.append(kpi_table)
    story.append(Spacer(1, 10))

    # Cost extremes sub-row
    ext_data = [
        ['Max Transaction', 'Min Transaction', 'Avg per Transaction', 'Vehicles'],
        [
            f'{currency}{max_tx:,.2f}',
            f'{currency}{min_tx:,.2f}',
            f'{currency}{float(analytics_data.get("avg_price_per_transaction", 0)):,.2f}',
            str(len(analytics_data.get('by_vehicle', []))),
        ],
    ]
    ext_table = Table(ext_data, colWidths=[42*mm]*4)
    ext_table.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 8),
        ('FONTSIZE', (0, 1), (-1, 1), 10),
        ('TEXTCOLOR', (0, 0), (-1, 0), BRAND_GREY),
        ('TEXTCOLOR', (0, 1), (-1, 1), BRAND_DARK),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('BACKGROUND', (0, 0), (-1, 0), BRAND_LIGHT),
        ('BOX', (0, 0), (-1, -1), 0.5, BRAND_GREY),
        ('INNERGRID', (0, 0), (-1, -1), 0.3, colors.HexColor('#e2e8f0')),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
    ]))
    story.append(ext_table)
    story.append(Spacer(1, 16))

    # ─── Daily Cost Trend Chart ───
    daily = analytics_data.get('daily_trend', [])
    if daily:
        story.append(Paragraph('Daily Fuel Cost Trend', section_style))
        chart_labels = [str(d.get('day', ''))[-5:] for d in daily]
        chart_values = [float(d.get('total_cost', 0)) for d in daily]
        chart = _draw_line_area('Daily Fuel Cost', chart_labels, chart_values)
        story.append(chart)
        story.append(Spacer(1, 16))

    # ─── Vehicle Summary Table ───
    by_vehicle = analytics_data.get('by_vehicle', [])
    if by_vehicle:
        story.append(Paragraph('Vehicle Fuel Summary', section_style))
        vheader = [
            Paragraph('#', cell_header_style),
            Paragraph('Vehicle', cell_header_style),
            Paragraph('Fill-ups', cell_header_style),
            Paragraph('Volume', cell_header_style),
            Paragraph('Cost', cell_header_style),
            Paragraph('Distance', cell_header_style),
            Paragraph('Avg MPG', cell_header_style),
        ]
        vtable_data = [vheader]
        for i, v in enumerate(by_vehicle, 1):
            name = f"{v.get('vehicle__make', '')} {v.get('vehicle__model', '')}".strip()
            plate = v.get('vehicle__license_plate', '') or ''
            vname = f'{name}' + (f' ({plate})' if plate else '')
            dist = v.get('distance')
            avg_mpg = v.get('avg_mpg')
            vtable_data.append([
                Paragraph(str(i), cell_style),
                Paragraph(vname or '—', cell_style),
                Paragraph(str(v.get('fill_count', 0)), cell_style),
                Paragraph(f"{float(v.get('total_gallons', 0)):,.1f}", cell_style),
                Paragraph(f'{currency}{float(v.get("total_cost", 0)):,.2f}', cell_style),
                Paragraph(f'{int(dist):,}' if dist else '—', cell_style),
                Paragraph(f'{avg_mpg}' if avg_mpg else '—', cell_style),
            ])

        veh_table = Table(vtable_data, colWidths=[
            8*mm, 52*mm, 18*mm, 22*mm, 28*mm, 22*mm, 20*mm,
        ], repeatRows=1)
        veh_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), BRAND_INDIGO),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 8),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
            ('GRID', (0, 0), (-1, -1), 0.3, colors.HexColor('#e2e8f0')),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ('LEFTPADDING', (0, 0), (-1, -1), 3),
            ('RIGHTPADDING', (0, 0), (-1, -1), 3),
        ]))
        story.append(veh_table)
        story.append(Spacer(1, 16))

    # ─── Top Stations ───
    by_station = analytics_data.get('by_station', [])[:10]
    if by_station:
        story.append(Paragraph('Top Fuel Stations', section_style))
        sheader = [
            Paragraph('#', cell_header_style),
            Paragraph('Station', cell_header_style),
            Paragraph('Location', cell_header_style),
            Paragraph('Fill-ups', cell_header_style),
            Paragraph('Volume', cell_header_style),
            Paragraph('Cost', cell_header_style),
        ]
        stable_data = [sheader]
        for i, s in enumerate(by_station, 1):
            stable_data.append([
                Paragraph(str(i), cell_style),
                Paragraph(s.get('station_name', '—'), cell_style),
                Paragraph(s.get('station_location', '—'), cell_style),
                Paragraph(str(s.get('count', 0)), cell_style),
                Paragraph(f"{float(s.get('total_gallons', 0)):,.1f}", cell_style),
                Paragraph(f'{currency}{float(s.get("total_cost", 0)):,.2f}', cell_style),
            ])

        st_table = Table(stable_data, colWidths=[
            8*mm, 40*mm, 50*mm, 18*mm, 22*mm, 30*mm,
        ], repeatRows=1)
        st_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), BRAND_INDIGO),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 8),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
            ('GRID', (0, 0), (-1, -1), 0.3, colors.HexColor('#e2e8f0')),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ('LEFTPADDING', (0, 0), (-1, -1), 3),
            ('RIGHTPADDING', (0, 0), (-1, -1), 3),
        ]))
        story.append(st_table)
        story.append(Spacer(1, 16))

    # ─── Monthly Trend ───
    monthly = analytics_data.get('monthly_trend', [])
    if monthly:
        story.append(Paragraph('Monthly Trend', section_style))
        mheader = [
            Paragraph('Month', cell_header_style),
            Paragraph('Volume', cell_header_style),
            Paragraph('Cost', cell_header_style),
        ]
        mtable_data = [mheader]
        for m in monthly:
            mtable_data.append([
                Paragraph(m.get('month', '—'), cell_style),
                Paragraph(f"{float(m.get('total_gallons', 0)):,.1f}", cell_style),
                Paragraph(f'{currency}{float(m.get("total_cost", 0)):,.2f}', cell_style),
            ])
        m_table = Table(mtable_data, colWidths=[50*mm, 50*mm, 60*mm], repeatRows=1)
        m_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), BRAND_INDIGO),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 8),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BRAND_LIGHT]),
            ('GRID', (0, 0), (-1, -1), 0.3, colors.HexColor('#e2e8f0')),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ('LEFTPADDING', (0, 0), (-1, -1), 3),
            ('RIGHTPADDING', (0, 0), (-1, -1), 3),
        ]))
        story.append(m_table)

    # ─── Footer ───
    story.append(Spacer(1, 20))
    story.append(HRFlowable(width='100%', thickness=0.5, color=BRAND_GREY))
    story.append(Spacer(1, 4))
    story.append(Paragraph(
        f'Generated by DomendraFleet on {datetime.now().strftime("%Y-%m-%d at %H:%M")} '
        f'· {tx_count} transactions · {len(by_vehicle)} vehicles · Total: {currency}{total_cost:,.2f}',
        ParagraphStyle('FleetFooter', parent=styles['Normal'], fontSize=8,
                       textColor=BRAND_GREY, alignment=TA_CENTER),
    ))

    doc.build(story)
    buf.seek(0)

    response = HttpResponse(buf, content_type='application/pdf')
    filename = f'fleet-fuel-report-{datetime.now().strftime("%Y%m%d")}.pdf'
    response['Content-Disposition'] = f'attachment; filename="{filename}"'
    return response
