import SwiftUI

// MARK: - Frequency Item Model
struct FrequencyItem: Identifiable, Hashable {
    var id: Int { hertz } // Use hertz as stable identifier
    let hertz: Int
    let name: String
    let description: String
    let subtitle: String
    let icon: String
    let color: Color
    let audioFileName: String // Will be the MP3 filename without extension
    
    // Custom hash function to use hertz
    func hash(into hasher: inout Hasher) {
        hasher.combine(hertz)
    }
    
    // Custom equality
    static func == (lhs: FrequencyItem, rhs: FrequencyItem) -> Bool {
        lhs.hertz == rhs.hertz
    }
    
    // All available frequencies
    static let allFrequencies: [FrequencyItem] = [
        FrequencyItem(
            hertz: 174,
            name: "174 Hz",
            description: "Marketed as pain relief, physical comfort, and feeling \"safe.\"",
            subtitle: "Base tone for body-healing or calming tracks",
            icon: "shield.fill",
            color: Color(red: 0.5, green: 0.3, blue: 0.6),
            audioFileName: "174-hz-pain-release"
        ),
        FrequencyItem(
            hertz: 285,
            name: "285 Hz",
            description: "Associated with tissue repair, \"energetic restructuring,\" and physical healing themes.",
            subtitle: "Regeneration, recovery, and self-healing",
            icon: "heart.circle.fill",
            color: Color(red: 0.4, green: 0.5, blue: 0.7),
            audioFileName: "285-hz-tissue-and-organ-healing-156262"
        ),
        FrequencyItem(
            hertz: 396,
            name: "396 Hz",
            description: "Framed as releasing fear, guilt, and emotional heaviness.",
            subtitle: "Letting go, forgiveness, and courage",
            icon: "flame.fill",
            color: Color(red: 0.8, green: 0.3, blue: 0.3),
            audioFileName: "396-hz-root-chakra-156263"
        ),
        FrequencyItem(
            hertz: 417,
            name: "417 Hz",
            description: "Linked to facilitating change, clearing old patterns, and overcoming challenges.",
            subtitle: "New identity and fresh start",
            icon: "arrow.triangle.2.circlepath",
            color: Color(red: 0.9, green: 0.5, blue: 0.2),
            audioFileName: "417-hz-sacral-chakra-156264"
        ),
        FrequencyItem(
            hertz: 432,
            name: "432 Hz",
            description: "An alternative tuning standard; described as softer, more natural, and relaxing than 440 Hz.",
            subtitle: "General meditation and heart-centered work",
            icon: "waveform.path.ecg",
            color: Color(red: 0.3, green: 0.7, blue: 0.5),
            audioFileName: "432-hz-tune-in-with-nature-156265"
        ),
        FrequencyItem(
            hertz: 528,
            name: "528 Hz",
            description: "Branded as the \"love\" or \"transformation\" frequency.",
            subtitle: "Self-love, self-worth, and gratitude",
            icon: "heart.fill",
            color: Color(red: 0.9, green: 0.3, blue: 0.5),
            audioFileName: "528-hz-solar-plexus-156266"
        ),
        FrequencyItem(
            hertz: 639,
            name: "639 Hz",
            description: "Associated with relationships, connection, communication, and harmony with others.",
            subtitle: "Love, friendship, and healthy boundaries",
            icon: "person.2.fill",
            color: Color(red: 0.2, green: 0.6, blue: 0.8),
            audioFileName: "639-hz-heart-chakra-156267"
        ),
        FrequencyItem(
            hertz: 741,
            name: "741 Hz",
            description: "Linked to intuition, \"detox,\" and mental clarity or truth telling.",
            subtitle: "Clarity, speaking your truth",
            icon: "eye.fill",
            color: Color(red: 0.4, green: 0.4, blue: 0.9),
            audioFileName: "741hz-throat-chakra-balancing-fostering-honest-expressions-157686"
        ),
        FrequencyItem(
            hertz: 852,
            name: "852 Hz",
            description: "Often tied to spiritual awareness, intuition, and \"returning to self.\"",
            subtitle: "Spiritual growth and higher-self",
            icon: "sparkles",
            color: Color(red: 0.7, green: 0.4, blue: 0.9),
            audioFileName: "852hz-third-eye-awakening-unleashing-intuition-clairvoyance-157687"
        )
    ]
}
