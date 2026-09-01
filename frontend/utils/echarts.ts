import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { BarChart, PieChart, LineChart, GaugeChart } from 'echarts/charts'
import {
  GridComponent,
  TooltipComponent,
  LegendComponent,
  TitleComponent,
  MarkLineComponent,
} from 'echarts/components'

let registered = false

export function setupECharts() {
  if (registered) return
  use([
    CanvasRenderer,
    BarChart,
    PieChart,
    LineChart,
    GaugeChart,
    GridComponent,
    TooltipComponent,
    LegendComponent,
    TitleComponent,
    MarkLineComponent,
  ])
  registered = true
}
