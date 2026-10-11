import SwiftUI

struct TriviaOptions: Hashable {
    var questionCount = 10
    var category = TriviaCategory.any
    var difficulty = TriviaDifficulty.easy
    var questionType = TriviaQuestionType.multiple
    var timeLimit = 60
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

    init(category: String, difficulty: String, text: String, correctAnswer: String, incorrectAnswers: [String]) {
        self.category = category
        self.difficulty = difficulty
        self.text = text
        self.correctAnswer = correctAnswer
        answers = (incorrectAnswers + [correctAnswer]).shuffled()
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

    func offlineQuestions(count: Int) -> [TriviaQuestion] {
        let questions = [
            TriviaQuestion(category: "General Knowledge", difficulty: "Easy", text: "What is the capital of France?", correctAnswer: "Paris", incorrectAnswers: ["Rome", "Madrid", "Berlin"]),
            TriviaQuestion(category: "Science & Nature", difficulty: "Easy", text: "Which planet is known as the Red Planet?", correctAnswer: "Mars", incorrectAnswers: ["Venus", "Jupiter", "Mercury"]),
            TriviaQuestion(category: "Geography", difficulty: "Easy", text: "Which is the largest ocean on Earth?", correctAnswer: "Pacific Ocean", incorrectAnswers: ["Atlantic Ocean", "Indian Ocean", "Arctic Ocean"]),
            TriviaQuestion(category: "History", difficulty: "Easy", text: "Who was the first president of the United States?", correctAnswer: "George Washington", incorrectAnswers: ["Abraham Lincoln", "Thomas Jefferson", "John Adams"]),
            TriviaQuestion(category: "Mathematics", difficulty: "Easy", text: "What is 12 multiplied by 8?", correctAnswer: "96", incorrectAnswers: ["84", "88", "108"]),
            TriviaQuestion(category: "Animals", difficulty: "Easy", text: "What is the largest land animal?", correctAnswer: "African elephant", incorrectAnswers: ["Giraffe", "Hippopotamus", "Polar bear"]),
            TriviaQuestion(category: "Entertainment: Books", difficulty: "Easy", text: "Who wrote Romeo and Juliet?", correctAnswer: "William Shakespeare", incorrectAnswers: ["Charles Dickens", "Jane Austen", "Mark Twain"]),
            TriviaQuestion(category: "Science: Computers", difficulty: "Easy", text: "What does CPU stand for?", correctAnswer: "Central Processing Unit", incorrectAnswers: ["Computer Personal Unit", "Central Program Utility", "Core Processing User"]),
            TriviaQuestion(category: "Sports", difficulty: "Easy", text: "How many players from one team are on the field in soccer?", correctAnswer: "11", incorrectAnswers: ["9", "10", "12"]),
            TriviaQuestion(category: "Mythology", difficulty: "Easy", text: "In Greek mythology, who is the god of the sea?", correctAnswer: "Poseidon", incorrectAnswers: ["Apollo", "Ares", "Hermes"])
        ]

        return Array(questions.prefix(count))
    }
}

struct ContentView: View {
    @State private var options = TriviaOptions()

    var body: some View {
        NavigationStack {
            ZStack {
                TriviaBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "brain.head.profile.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(.white)
                                .symbolEffect(.pulse)

                            Text("Ready to play?")
                                .font(.largeTitle.bold())

                            Text("Choose your challenge and put your knowledge to the test.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.75))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(.white)
                        .padding(.top, 24)

                        VStack(spacing: 0) {
                            optionRow(icon: "number.circle.fill", title: "Questions") {
                                Text("\(options.questionCount)")
                                    .font(.headline.monospacedDigit())
                                    .frame(minWidth: 28)

                                Stepper(
                                    "\(options.questionCount)",
                                    value: $options.questionCount,
                                    in: 5...20
                                )
                                .labelsHidden()
                            }

                            Divider()

                            optionRow(icon: "square.grid.2x2.fill", title: "Category") {
                                Picker("Category", selection: $options.category) {
                                    ForEach(TriviaCategory.allCases) { category in
                                        Text(category.rawValue).tag(category)
                                    }
                                }
                                .labelsHidden()
                            }

                            Divider()

                            optionRow(icon: "timer", title: "Time Limit") {
                                Picker("Time limit", selection: $options.timeLimit) {
                                    Text("30 sec").tag(30)
                                    Text("1 min").tag(60)
                                    Text("2 min").tag(120)
                                    Text("3 min").tag(180)
                                }
                                .labelsHidden()
                            }

                            Divider()

                            optionRow(icon: "speedometer", title: "Difficulty") {
                                Picker("Difficulty", selection: $options.difficulty) {
                                    ForEach(TriviaDifficulty.allCases) { difficulty in
                                        Text(difficulty.title).tag(difficulty)
                                    }
                                }
                                .labelsHidden()
                            }

                            Divider()

                            optionRow(icon: "checklist", title: "Question Type") {
                                Picker("Question type", selection: $options.questionType) {
                                    ForEach(TriviaQuestionType.allCases) { type in
                                        Text(type.title).tag(type)
                                    }
                                }
                                .labelsHidden()
                            }
                        }
                        .padding(.horizontal)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        }

                        NavigationLink {
                            QuizView(options: options)
                        } label: {
                            Label("Start Trivia", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.purple)
                    }
                    .padding()
                    .frame(maxWidth: 620)
                }
            }
        }
    }

    private func optionRow<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .frame(width: 28)

            Text(title)
                .font(.headline)

            Spacer()

            content()
        }
        .padding(.vertical, 16)
    }
}

struct TriviaBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.indigo.opacity(0.95), Color.blue.opacity(0.72), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.purple.opacity(0.28))
                .frame(width: 320, height: 320)
                .blur(radius: 40)
                .offset(x: 90, y: -100)
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
    @State private var timeRemaining = 0
    @State private var didTimeExpire = false

    private let service = TriviaService()

    var body: some View {
        ZStack {
            TriviaBackground()

            if isLoading {
                ProgressView("Loading questions...")
                    .tint(.white)
                    .foregroundStyle(.white)
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
        .task(id: isLoading) {
            guard !isLoading, errorMessage == nil, !questions.isEmpty else { return }
            await runTimer()
        }
        .alert(didTimeExpire ? "Time’s Up!" : "Quiz Complete", isPresented: $isShowingScore) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You scored \(score) out of \(questions.count).")
        }
    }

    private var quizContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack {
                    Label("Your progress", systemImage: "sparkles")
                    Spacer()
                    Label("\(timeRemaining)s", systemImage: "timer")
                        .foregroundStyle(timeRemaining <= 10 ? .red : .white)
                        .monospacedDigit()
                    Divider()
                        .frame(height: 16)
                    Text("\(selections.count) of \(questions.count)")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

                ProgressView(value: Double(selections.count), total: Double(questions.count))
                    .tint(.purple)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding([.horizontal, .top])

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
                    submitQuiz()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(selections.count != questions.count || hasSubmitted)
            }
            .padding()
            .background(.ultraThinMaterial)
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
        timeRemaining = options.timeLimit
        didTimeExpire = false

        do {
            questions = try await service.fetchQuestions(options: options)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                questions = service.offlineQuestions(count: options.questionCount)
            case .timedOut:
                questions = service.offlineQuestions(count: options.questionCount)
            default:
                errorMessage = "Network error: \(urlError.localizedDescription)"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    private func runTimer() async {
        while timeRemaining > 0 && !hasSubmitted {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }

            guard !Task.isCancelled, !hasSubmitted else { return }
            timeRemaining -= 1
        }

        if timeRemaining == 0 && !hasSubmitted {
            didTimeExpire = true
            submitQuiz()
        }
    }

    private func submitQuiz() {
        calculateScore { calculatedScore in
            score = calculatedScore
            hasSubmitted = true
            isShowingScore = true
        }
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 14, y: 7)
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
