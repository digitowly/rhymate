import Foundation

// MARK: - AI Feature Settings

enum AIFeatures {
    static let defaultsKey = "ai.enabled"

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: defaultsKey) as? Bool ?? true
    }

    static var isHardwareAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) { return FoundationModelRhymer.isAvailable }
        #endif
        return false
    }

    static var isAvailable: Bool { isEnabled && isHardwareAvailable }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
enum FoundationModelRhymerError: Error { case noResults, timedOut }

@available(iOS 26.0, macOS 26.0, *)
struct FoundationModelRhymer {

    @Generable
    struct RhymeSuggestions {
        @Guide(description: "Words or short phrases (1–3 words) that rhyme with the input")
        var words: [String]
    }

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    private static func makeBuddySession() -> LanguageModelSession {
        LanguageModelSession(instructions: """
            You are a creative lyric writer for a songwriting app.
            Given a song line, suggest lines that could come next — lines that rhyme with \
            or echo its ending sound. Aim for poetic, varied language, not generic templates.
            Output only the lyric lines, one per line. No explanations, no preamble.
            Example — "this is a song I wrote":
            every word a note
            all she wrote
            let it float
            left me remote
            took the antidote
            """)
    }

    private static func makeLyricSession() -> LanguageModelSession {
        LanguageModelSession(instructions: """
            You are a creative lyric writer for a songwriting app.
            Given a word, generate short lyric phrases (2–5 words) that could end a line of \
            song lyrics and rhyme with that word. Aim for poetic, evocative language — \
            not generic word substitutions.
            Output only the lyric phrases, one per line. No explanations, no preamble.
            Example — "wrote":
            all she wrote
            hit the right note
            let it float
            learned by rote
            took the antidote
            """)
    }

    // MARK: - Sessions

    private static func makeWordSession() -> LanguageModelSession {
        LanguageModelSession(instructions: """
            You are a rhyming dictionary used in a music composition app.
            Given a word, output words that share its ending sound — perfect rhymes first, then near rhymes.
            Output only the rhyming words, one per line. No explanations, no preamble.
            Example — "night": right, light, sight, ignite, delight, midnight
            """)
    }

    private static func makePhraseSession() -> LanguageModelSession {
        LanguageModelSession(instructions: """
            You are a rhyming dictionary used in a music composition app.
            Given a word or short phrase ending, output words and short phrases (1–4 words) \
            that share the same ending vowel-consonant sound.
            Output only the rhyming matches, one per line. Mix single words and multi-word phrases.
            Example — "dont mind": kind, find, unwind, left behind, speak your mind, one of a kind
            Do not include the input itself. No explanations, no preamble.
            """)
    }

    // MARK: - Public API

    /// Suggests lyric lines that could follow `line` in a song.
    func lyricSuggestions(forLine line: String) async throws -> [String] {
        let session = Self.makeBuddySession()
        let response = try await withTimeout(seconds: 10) {
            try await session.respond(to: "Suggest next lines for: \(line)")
        }
        let results = parseLines(response.content, excluding: [])
        guard !results.isEmpty else { throw FoundationModelRhymerError.noResults }
        return results
    }

    /// Generates creative lyric endings that rhyme with `word`.
    /// The model works freely without a constrained word list — passing one
    /// caused it to produce mechanical substitutions rather than creative phrases.
    func lyricEndings(rhymingWith word: String) async throws -> [String] {
        let session = Self.makeLyricSession()
        let response = try await withTimeout(seconds: 10) {
            try await session.respond(to: "Lyric line endings that rhyme with: \(word)")
        }
        let results = parseLines(response.content, excluding: [])
        guard !results.isEmpty else { throw FoundationModelRhymerError.noResults }
        return results
    }

    /// Supplements Datamuse results with additional rhymes not already in the list.
    func supplement(word: String, excluding existing: [String]) async throws -> [String] {
        let exclusion = existing.isEmpty ? "" : " Exclude: \(existing.prefix(20).joined(separator: ", "))."
        let session = Self.makeWordSession()
        let response = try await withTimeout(seconds: 8) {
            try await session.respond(
                to: "Rhyming words for: \(word)\(exclusion)",
                generating: RhymeSuggestions.self
            )
        }
        return clean(response.content.words, excluding: existing)
    }

    /// Primary source for phrase queries.
    /// Only the rhyming tail (last 1–2 words) is sent to the model — passing a full
    /// phrase can cause safety guardrails to trigger on unrelated words earlier in
    /// the sentence. The tail carries all the phonetic information we need.
    func rhymes(forPhrase phrase: String) async throws -> [String] {
        let tail = rhymingTail(of: phrase)
        let session = Self.makePhraseSession()
        let response = try await withTimeout(seconds: 8) {
            try await session.respond(to: "Rhyme matches for: \(tail)")
        }
        let results = parseLines(response.content, excluding: [])
        guard !results.isEmpty else { throw FoundationModelRhymerError.noResults }
        return results
    }

    // MARK: - Helpers

    /// Extracts the last 1–2 words — the part that determines the rhyme sound.
    private func rhymingTail(of phrase: String) -> String {
        let words = phrase.split(separator: " ").map(String.init)
        return words.count >= 2 ? words.suffix(2).joined(separator: " ") : words.last ?? phrase
    }

    /// Runs `operation` and cancels it if it hasn't completed within `seconds`.
    private func withTimeout<T: Sendable>(
        seconds: Double,
        _ operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw FoundationModelRhymerError.timedOut
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    private func clean(_ words: [String], excluding: [String]) -> [String] {
        let known = Set(excluding)
        return words
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !known.contains($0) }
    }

    private func parseLines(_ text: String, excluding: [String]) -> [String] {
        // If the response is a refusal, discard it so the caller falls back to Datamuse.
        let lower = text.lowercased()
        let refusalSignals = ["cannot assist", "i'm unable", "i am unable", "not able to",
                              "violat", "inappropriat", "i'm sorry, but", "i cannot"]
        if refusalSignals.contains(where: { lower.contains($0) }) { return [] }

        let known = Set(excluding)
        return text
            .components(separatedBy: .newlines)
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                guard !line.isEmpty && !known.contains(line) else { return false }
                if line.hasSuffix(":") { return false }
                let preamble = ["here is", "here are", "the following", "rhyming words", "rhyming phrases"]
                if preamble.contains(where: { line.hasPrefix($0) }) { return false }
                return true
            }
    }
}
#endif
