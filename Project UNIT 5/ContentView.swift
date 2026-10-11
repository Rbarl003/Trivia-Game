import SwiftUI

struct TriviaOptions: Hashable {
    var questionCount = 10
    var category = TriviaCategory.any
    var difficulty = TriviaDifficulty.easy
    var questionType = TriviaQuestionType.multiple
}

enum TriviaCategory: String, CaseIterable, Identifiable {
    case any = "Any Category"
    case generalKnowledge = "General Knowledge"
    case books = "Entertainment: Books"
    case film = "Entertainment: Film"
    case music = "Entertainment: Music"
    case television = "Entertainment: Television"
    case videoGames = "Entertainment: Video Games"
    case scienceNature = "Science & Nature"
    case computers = "Science: Computers"
    case mathematics = "Science: Mathematics"
    case mythology = "Mythology"
    case sports = "Sports"
    case geography = "Geography"
    case history = "History"
    case politics = "Politics"
    case art = "Art"
    case animals = "Animals"

    var id: Self { self }

    var apiValue: String? {
        switch self {
        case .any: nil
        case .generalKnowledge: "9"
        case .books: "10"
        case .film: "11"
        case .music: "12"
        case .television: "14"
        case .videoGames: "15"
        case .scienceNature: "17"
        case .computers: "18"
        case .mathematics: "19"
        case .mythology: "20"
        case .sports: "21"
        case .geography: "22"
        case .history: "23"
        case .politics: "24"
        case .art: "25"
        case .animals: "27"
        }
    }
}

enum TriviaDifficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }
}

enum TriviaQuestionType: String, CaseIterable, Identifiable {
    case multiple
    case boolean

    var id: Self { self }

    var title: String {
        switch self {
        case .multiple: "Multiple Choice"
        case .boolean: "True / False"
        }
    }
}

struct TriviaResponse: Decodable {
    let responseCode: Int
    let results: [TriviaAPIQuestion]

    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case results
    }
}

struct TriviaAPIQuestion: Decodable {
    let category: String
    let difficulty: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    enum CodingKeys: String, CodingKey {
        case category
        case difficulty
        case question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
}

struct TriviaQuestion: Identifiable, Equatable {
    let id = UUID()
    let category: String
    let difficulty: String
    let text: String
    let correctAnswer: String
    let answers: [String]

    init(apiQuestion: TriviaAPIQuestion) {
        category = apiQuestion.category.decodedTriviaText
        difficulty = apiQuestion.difficulty.capitalized
        text = apiQuestion.question.decodedTriviaText
        correctAnswer = apiQuestion.correctAnswer.decodedTriviaText
        answers = (apiQuestion.incorrectAnswers + [apiQuestion.correctAnswer])
            .map(\.decodedTriviaText)
            .shuffled()
    }
}

extension String {
    var decodedTriviaText: String {
        removingPercentEncoding ?? self
    }
}

enum TriviaServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case noQuestions

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The trivia request could not be created."
        case .invalidResponse:
            "The trivia service returned an invalid response."
        case .apiError:
            "The trivia service could not create a quiz with those options."
        case .noQuestions:
            "No questions matched those options. Try a different category or difficulty."
        }
    }
}

struct TriviaService {
    func fetchQuestions(options: TriviaOptions) async throws -> [TriviaQuestion] {
        var components = URLComponents(string: "https://opentdb.com/api.php")
        var queryItems = [
            URLQueryItem(name: "amount", value: String(options.questionCount)),
            URLQueryItem(name: "difficulty", value: options.difficulty.rawValue),
            URLQueryItem(name: "type", value: options.questionType.rawValue),
            URLQueryItem(name: "encode", value: "url3986")
        ]

        if let category = options.category.apiValue {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw TriviaServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TriviaServiceError.invalidResponse
        }

        let triviaResponse = try JSONDecoder().decode(TriviaResponse.self, from: data)

        guard triviaResponse.responseCode == 0 else {
            throw TriviaServiceError.apiError(triviaResponse.responseCode)
        }

        let questions = triviaResponse.results.map(TriviaQuestion.init)

        guard !questions.isEmpty else {
            throw TriviaServiceError.noQuestions
        }

        return questions
    }
}

struct ContentView: View {
    @State private var options = TriviaOptions()

    var body: some View {
        NavigationStack {
            Form {
                Section("Quiz Options") {
                    Stepper(
                        "Number of questions: \(options.questionCount)",
                        value: $options.questionCount,
                        in: 5...20
                    )

                    Picker("Category", selection: $options.category) {
                        ForEach(TriviaCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }

                    Picker("Difficulty", selection: $options.difficulty) {
                        ForEach(TriviaDifficulty.allCases) { difficulty in
                            Text(difficulty.title).tag(difficulty)
                        }
                    }

                    Picker("Question type", selection: $options.questionType) {
                        ForEach(TriviaQuestionType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        QuizView(options: options)
                    } label: {
                        Label("Start Trivia", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Trivia Game")
        }
    }
}

struct QuizView: View {
    let options: TriviaOptions

    @State private var questions: [TriviaQuestion] = []
    @State private var selections: [UUID: String] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var hasSubmitted = false
    @State private var score = 0
    @State private var isShowingScore = false

    private let service = TriviaService()

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading questions...")
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Couldn’t Load Quiz", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Try Again") {
                        Task {
                            await loadQuestions()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                quizContent
            }
        }
        .navigationTitle("Trivia Challenge")
        .task {
            guard questions.isEmpty else { return }
            await loadQuestions()
        }
        .alert("Quiz Complete", isPresented: $isShowingScore) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You scored \(score) out of \(questions.count).")
        }
    }

    private var quizContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                        QuestionCardView(
                            number: index + 1,
                            question: question,
                            selectedAnswer: selections[question.id],
                            hasSubmitted: hasSubmitted,
                            onSelect: { answer in
                                selections[question.id] = answer
                            }
                        )
                    }
                }
                .padding()
            }

            VStack(spacing: 8) {
                if hasSubmitted {
                    Text("Score: \(score) / \(questions.count)")
                        .font(.headline)
                }

                Button(hasSubmitted ? "Submitted" : "Submit Answers") {
                    calculateScore { calculatedScore in
                        score = calculatedScore
                        hasSubmitted = true
                        isShowingScore = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(selections.count != questions.count || hasSubmitted)
            }
            .padding()
            .background(.bar)
        }
    }

    @MainActor
    private func loadQuestions() async {
        isLoading = true
        errorMessage = nil
        questions = []
        selections = [:]
        hasSubmitted = false
        score = 0

        do {
            questions = try await service.fetchQuestions(options: options)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func calculateScore(completion: (Int) -> Void) {
        let calculatedScore = questions.reduce(into: 0) { total, question in
            if selections[question.id] == question.correctAnswer {
                total += 1
            }
        }

        completion(calculatedScore)
    }
}

struct QuestionCardView: View {
    let number: Int
    let question: TriviaQuestion
    let selectedAnswer: String?
    let hasSubmitted: Bool
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Question \(number)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(question.text)
                .font(.headline)

            Text("\(question.category) • \(question.difficulty)")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(question.answers, id: \.self) { answer in
                Button {
                    guard !hasSubmitted else { return }
                    onSelect(answer)
                } label: {
                    HStack {
                        Text(answer)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if selectedAnswer == answer {
                            Image(systemName: hasSubmitted ? resultIcon(for: answer) : "checkmark.circle.fill")
                        } else if hasSubmitted && answer == question.correctAnswer {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(answerColor(for: answer), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(answerForegroundColor(for: answer))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(answer)
                .accessibilityValue(selectedAnswer == answer ? "Selected" : "Not selected")
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }

    private func answerColor(for answer: String) -> Color {
        if hasSubmitted {
            if answer == question.correctAnswer {
                return .green.opacity(0.22)
            }

            if selectedAnswer == answer {
                return .red.opacity(0.22)
            }

            return Color.secondary.opacity(0.10)
        }

        return selectedAnswer == answer
            ? .blue.opacity(0.22)
            : Color.secondary.opacity(0.10)
    }

    private func answerForegroundColor(for answer: String) -> Color {
        if hasSubmitted {
            if answer == question.correctAnswer {
                return .green
            }

            if selectedAnswer == answer {
                return .red
            }
        }

        return selectedAnswer == answer ? .blue : .primary
    }

    private func resultIcon(for answer: String) -> String {
        answer == question.correctAnswer ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
}

#Preview {
    ContentView()
}
