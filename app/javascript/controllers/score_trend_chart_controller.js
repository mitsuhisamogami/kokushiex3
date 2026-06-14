import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Connects to data-controller="score-trend-chart"
export default class extends Controller {
  static targets = ["canvas", "empty"]
  static values = { scores: Array }

  connect() {
    if (this.scoresValue.length === 0) {
      this.canvasTarget.classList.add("hidden")
      this.emptyTarget.classList.remove("hidden")
      return
    }

    this.drawChart()
  }

  disconnect() {
    this.destroyChart()
  }

  drawChart() {
    this.destroyChart()

    this.chart = new Chart(this.canvasTarget, {
      type: "line",
      data: {
        labels: this.scoresValue.map((score) => score.label),
        datasets: [
          {
            label: "得点率",
            data: this.scoresValue.map((score) => score.percentage),
            borderColor: "#2563eb",
            backgroundColor: "rgba(37, 99, 235, 0.12)",
            pointBackgroundColor: "#2563eb",
            pointBorderColor: "#1e40af",
            pointRadius: 4,
            pointHoverRadius: 6,
            borderWidth: 2,
            fill: true,
            tension: 0.25,
            customScores: this.scoresValue,
          },
          {
            label: "合格基準",
            data: this.scoresValue.map((score) => score.pass_percentage),
            borderColor: "#059669",
            backgroundColor: "rgba(5, 150, 105, 0.08)",
            pointBackgroundColor: "#059669",
            pointBorderColor: "#047857",
            pointRadius: 4,
            pointHoverRadius: 6,
            borderWidth: 2,
            borderDash: [6, 4],
            fill: false,
            tension: 0.25,
            customScores: this.scoresValue,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            grid: {
              color: "rgba(148, 163, 184, 0.25)",
            },
            ticks: {
              color: "#475569",
              callback: (value) => `${value}%`,
            },
          },
          x: {
            grid: {
              color: "rgba(148, 163, 184, 0.18)",
            },
            ticks: {
              color: "#475569",
            },
          },
        },
        plugins: {
          legend: {
            display: true,
            labels: {
              color: "#475569",
              usePointStyle: true,
            },
          },
          tooltip: {
            callbacks: {
              title: (items) => this.scoresValue[items[0].dataIndex].test,
              label: (context) => this.scoreLabel(context.dataset.label, context.dataset.customScores[context.dataIndex]),
            },
          },
        },
      },
    })
  }

  scoreLabel(label, score) {
    if (label === "合格基準") {
      return `${label}: ${score.required_score}/${score.full_score}点 (${score.pass_percentage}%)`
    }

    return `${label}: ${score.total_score}/${score.full_score}点 (${score.percentage}%)`
  }

  destroyChart() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }
}
