//
//  ContentView.swift
//  GamesTabViewExample
//
//  Created by Guh F on 21/07/25.


import SwiftUI
import Combine


// MARK: - Modelo de Dados (Model)
struct Game: Codable, Identifiable {
    let id = UUID()
    var game: String
    var gameLink: String?
    var year: Int
    var dev: String
    var devLink: String?
    var publisher: String
    var publisherLink: String?
    var platform: String
    var platformLink: String?

    enum CodingKeys: String, CodingKey {
        case game = "Game", gameLink = "GameLink", year = "Year", dev = "Dev", devLink = "DevLink", publisher = "Publisher", publisherLink = "PublisherLink", platform = "Platform", platformLink = "PlatformLink"
    }
}

// MARK: - Estado do Aplicativo (App State)
// Um objeto para gerenciar o estado compartilhado da UI.
class AppState: ObservableObject {
    @Published var searchText = ""
}

// Enum para gerenciar as abas de forma segura
enum AppTab {
    case games, add, about, search
}

// MARK: - Carregador de Dados (Data Loader)
class DataLoader: ObservableObject {
    @Published var games = [Game]()

    init() {
        loadData()
    }

    func loadData() {
        guard let url = Bundle.main.url(forResource: "games", withExtension: "json") else {
            fatalError("Não foi possível encontrar o arquivo games.json no bundle.")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Não foi possível carregar os dados do arquivo.")
        }
        do {
            self.games = try JSONDecoder().decode([Game].self, from: data)
        } catch {
            fatalError("Falha ao decodificar o arquivo games.json: \(error)")
        }
    }
    
    func addGame(_ game: Game) {
        games.insert(game, at: 0)
    }
}

// MARK: - Tela de Adicionar Jogo (Add Game View)
struct AddGameView: View {
    @EnvironmentObject var dataLoader: DataLoader
    
    @State private var title = ""
    @State private var developer = ""
    @State private var publisher = ""
    @State private var yearString = ""
    
    @State private var showingAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalhes do Jogo")) {
                    TextField("Título do Jogo", text: $title)
                    TextField("Desenvolvedora", text: $developer)
                    TextField("Publicadora", text: $publisher)
                    TextField("Ano de Lançamento", text: $yearString)
                        .keyboardType(.numberPad)
                }
                
                Button("Adicionar Jogo") {
                    saveGame()
                }
            }
            .navigationTitle("Novo Jogo")
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Campos Inválidos"), message: Text("Por favor, preencha todos os campos corretamente. O ano deve ser um número."), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func saveGame() {
        guard !title.isEmpty, !developer.isEmpty, !publisher.isEmpty, let year = Int(yearString) else {
            showingAlert = true
            return
        }
        
        let newGame = Game(game: title, gameLink: nil, year: year, dev: developer, devLink: nil, publisher: publisher, publisherLink: nil, platform: "the 3DS", platformLink: "https://en.wikipedia.org/wiki/Nintendo_3DS")
        
        dataLoader.addGame(newGame)
        
        title = ""
        developer = ""
        publisher = ""
        yearString = ""
    }
}


// MARK: - Tela de Detalhes do Jogo (Detail View)
struct GameDetailView: View {
    let game: Game

    var body: some View {
        Form {
            Section(header: Text("Informações Gerais")) {
                InfoRow(label: "Título", value: game.game)
                InfoRow(label: "Ano", value: "\(game.year)")
                InfoRow(label: "Plataforma", value: game.platform)
            }
            Section(header: Text("Desenvolvimento")) {
                InfoRow(label: "Desenvolvedora", value: game.dev)
                InfoRow(label: "Publicadora", value: game.publisher)
            }
            Section(header: Text("Links")) {
                if let urlString = game.gameLink, let url = URL(string: urlString) { Link("Link do Jogo", destination: url) }
                if let urlString = game.devLink, let url = URL(string: urlString) { Link("Link da Desenvolvedora", destination: url) }
                if let urlString = game.publisherLink, let url = URL(string: urlString) { Link("Link da Publicadora", destination: url) }
                if let urlString = game.platformLink, let url = URL(string: urlString) { Link("Link da Plataforma", destination: url) }
            }
        }
        .navigationTitle(game.game)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// View auxiliar para exibir uma linha de informação
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundColor(.gray)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Acessório da TabView (Accessory View) - Atualizado
struct GameStatsAccessoryView: View {
    let count: Int
    let isSearching: Bool
    
    var body: some View {
        HStack {
            // Mostra texto diferente se o usuário está buscando ou não
            Text(isSearching ? "\(count) Resultados" : "\(count) Jogos na Lista")
                .font(.callout.weight(.medium))
            Spacer()
        }
        .frame(height: 44)
        .padding(.horizontal)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Tela da Lista de Jogos (Games List Tab)
struct GamesListView: View {
    // Recebe a lista de jogos já filtrada para exibir
    let games: [Game]

    var body: some View {
        // A NavigationView agora é controlada pela TabView quando necessário
        List(games) { game in
            NavigationLink(destination: GameDetailView(game: game)) {
                VStack(alignment: .leading) {
                    Text(game.game).font(.headline)
                    Text(game.dev).font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Jogos de 3DS")
    }
}

// MARK: - Tela Sobre (About Tab)
struct AboutView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                Text("3DS Game Explorer")
                    .font(.largeTitle)
                    .bold()
                Text("Este app demonstra as novas funcionalidades da TabView no SwiftUI, incluindo o TabViewBottomAccessoryPlacement.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Sobre")
        }
    }
}


// MARK: - View Principal com TabView (Main View)
struct ContentView: View {
    @StateObject private var dataLoader = DataLoader()
    @StateObject private var appState = AppState()
    @State private var selectedTab: AppTab = .games

    // A lógica de filtragem agora reside na view principal
    private var filteredGames: [Game] {
        if appState.searchText.isEmpty {
            return dataLoader.games
        } else {
            return dataLoader.games.filter { $0.game.localizedCaseInsensitiveContains(appState.searchText) }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // Aba 1: Lista de Jogos - Passa a lista filtrada
            Tab("Jogos", systemImage: "list.bullet", value: .games) {
                NavigationView { GamesListView(games: filteredGames) }
            }
            
            // Aba 2: Adicionar Jogo
            Tab("Adicionar", systemImage: "plus.circle.fill", value: .add) {
                AddGameView()
            }

            // Aba 3: Sobre
            Tab("Sobre", systemImage: "info.circle.fill", value: .about) {
                AboutView()
            }
            
            // Aba 4: Busca - Passa a lista filtrada
            Tab("Buscar", systemImage: "magnifyingglass", value: .search, role: .search) {
                NavigationView {
                    GamesListView(games: filteredGames)
                }
            }
        }
        .searchable(text: $appState.searchText, placement: .automatic)
        // Lógica atualizada para mostrar o acessório
        .tabViewBottomAccessory {
            // Mostra o acessório apenas na aba de jogos e quando não está buscando
            if selectedTab == .games && appState.searchText.isEmpty {
                GameStatsAccessoryView(count: dataLoader.games.count, isSearching: false)
            } else if selectedTab == .search && !appState.searchText.isEmpty {
                // Na aba de busca, mostra o número de resultados
                GameStatsAccessoryView(count: filteredGames.count, isSearching: true)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .environmentObject(dataLoader)
        .environmentObject(appState)
    }
}
