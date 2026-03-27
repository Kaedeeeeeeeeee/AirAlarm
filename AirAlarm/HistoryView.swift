import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(LocalizationManager.self) private var loc
    @Query(sort: \SleepRecord.date, order: .reverse) private var records: [SleepRecord]

    var body: some View {
        List {
            if records.isEmpty {
                Text(loc.t("no_history"))
                    .foregroundStyle(.white.opacity(0.4))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(records) { record in
                    recordRow(record)
                        .listRowBackground(Color.white.opacity(0.05))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(loc.t("history"))
    }

    private func recordRow(_ record: SleepRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date
            Text(record.date, style: .date)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.4))

            HStack {
                // Sleep → Wake times
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill").font(.caption2).foregroundStyle(.purple)
                        Text(record.sleepTime, style: .time).font(.subheadline)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "sun.max.fill").font(.caption2).foregroundStyle(.yellow)
                        Text(record.wakeTime, style: .time).font(.subheadline)
                    }
                }
                .foregroundStyle(.white.opacity(0.8))

                Spacer()

                // Duration + cycles
                VStack(alignment: .trailing, spacing: 2) {
                    Text(record.durationText)
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                    Text("\(record.cycles) \(loc.t("cycles"))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.vertical, 4)
    }
}
