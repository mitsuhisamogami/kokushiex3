import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Connects to data-controller="tag-score-chart"
export default class extends Controller {
  static targets = ["canvas", "empty", "note", "tab"]
  static values = { summary: Object }

  connect() {
    this.currentSectionKey = Object.keys(this.summaryValue)[0]
    this.render()
  }

  disconnect() {
    this.destroyChart()
  }

  select(event) {
    this.currentSectionKey = event.currentTarget.dataset.sectionKey
    this.render()
  }

  render() {
    const section = this.summaryValue[this.currentSectionKey]
    const tags = section.tags

    this.updateTabs()
    this.noteTarget.textContent = section.note

    if (tags.length === 0) {
      this.destroyChart()
      this.canvasTarget.classList.add("hidden")
      this.emptyTarget.classList.remove("hidden")
      return
    }

    this.canvasTarget.classList.remove("hidden")
    this.emptyTarget.classList.add("hidden")
    this.drawChart(tags)
  }

  drawChart(tags) {
    this.destroyChart()

    this.chart = new Chart(this.canvasTarget, {
      type: "bar",
      data: {
        labels: tags.map((tag) => tag.name),
        datasets: [
          {
            label: "正答率",
            data: tags.map((tag) => tag.percentage),
            backgroundColor: "#2563eb",
            borderColor: "#1e40af",
            borderWidth: 1,
            customScores: tags,
          },
        ],
      },
      options: {
        indexAxis: "y",
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: {
            beginAtZero: true,
            max: 100,
            ticks: {
              callback: (value) => `${value}%`,
            },
          },
        },
        plugins: {
          legend: {
            display: false,
          },
          tooltip: {
            callbacks: {
              label: (context) => this.scoreLabel(context.dataset.customScores[context.dataIndex]),
            },
          },
        },
      },
      plugins: [this.barLabelPlugin()],
    })
  }

  updateTabs() {
    this.tabTargets.forEach((tab) => {
      const selected = tab.dataset.sectionKey === this.currentSectionKey

      tab.classList.toggle("border-sky-500", selected)
      tab.classList.toggle("text-sky-600", selected)
      tab.classList.toggle("border-transparent", !selected)
      tab.classList.toggle("text-gray-500", !selected)
    })
  }

  scoreLabel(tag) {
    return `${tag.earned_score}/${tag.total_score}点 (${tag.percentage}%)`
  }

  barLabelPlugin() {
    return {
      id: "scoreLabels",
      afterDatasetsDraw: (chart) => {
        const { ctx } = chart
        const meta = chart.getDatasetMeta(0)
        const scores = chart.data.datasets[0].customScores

        ctx.save()
        ctx.fillStyle = "#374151"
        ctx.font = "12px sans-serif"
        ctx.textBaseline = "middle"

        meta.data.forEach((bar, index) => {
          ctx.fillText(this.scoreLabel(scores[index]), bar.x + 8, bar.y)
        })

        ctx.restore()
      },
    }
  }

  destroyChart() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }
}
