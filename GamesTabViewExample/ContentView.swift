//
//  ContentView.swift
//  GamesTabViewExample
//
//  Created by Guh F on 21/07/25.


import SwiftUI
internal import Combine

// MARK: - Modelo de Dados (Model)
// Esta struct representa um único jogo, correspondendo à estrutura do JSON.
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

// MARK: - Carregador de Dados (Data Loader)
// Uma classe observável para carregar e compartilhar os dados do JSON.
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
    
    // Função para adicionar um novo jogo à lista
    func addGame(_ game: Game) {
        games.insert(game, at: 0)
    }
}

// MARK: - Tela de Adicionar Jogo (Add Game View)
struct AddGameView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @Environment(\.presentationMode) var presentationMode
    
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
        
        // Limpa os campos após salvar
        title = ""
        developer = ""
        publisher = ""
        yearString = ""
        
        // Idealmente, aqui você daria um feedback ao usuário, como fechar a view
        // ou mostrar uma confirmação. Por simplicidade, apenas limpamos os campos.
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

// MARK: - Acessório da TabView (Accessory View)
// Esta é a view que será mostrada acima da barra de abas.
struct GameStatsAccessoryView: View {
    // Lê o estado de posicionamento do ambiente.
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    // Acessa os dados dos jogos para mostrar estatísticas.
    @EnvironmentObject var dataLoader: DataLoader

    var body: some View {
        // A aparência da view muda com base no posicionamento.
        if placement == .expanded {
            // Versão expandida: Mostra mais detalhes.
            HStack {
                Text("Total de Jogos na Lista:")
                Spacer()
                Text("\(dataLoader.games.count)")
                    .bold()
            }
            .padding(.horizontal)
            .frame(height: 44) // Altura padrão para um acessório
            .background(.ultraThinMaterial)

        } else {
            // Versão em linha (inline): Mais compacta.
            HStack {
                Spacer()
                Text("\(dataLoader.games.count) Jogos")
                    .font(.caption)
                    .bold()
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Tela da Lista de Jogos (Games List Tab)
struct GamesListView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @State private var searchText = ""

    var filteredGames: [Game] {
        searchText.isEmpty ? dataLoader.games : dataLoader.games.filter { $0.game.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            List(filteredGames) { game in
                NavigationLink(destination: GameDetailView(game: game)) {
                    VStack(alignment: .leading) {
                        Text(game.game).font(.headline)
                        Text(game.dev).font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Jogos de 3DS")
            .searchable(text: $searchText, prompt: "Buscar por nome do jogo")
        }
    }
}

// MARK: - Tela Sobre (About Tab)
struct AboutView: View {
    var body: some View {
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
    }
}


// MARK: - View Principal com TabView (Main View)
struct ContentView: View {
    // Cria uma única instância do DataLoader e a compartilha com as subviews.
    @StateObject private var dataLoader = DataLoader()

    var body: some View {
        TabView {
            // Aba 1: Lista de Jogos
            GamesListView()
                .tabItem {
                    Label("Jogos", systemImage: "list.bullet")
                }
            
            // Aba 2: Adicionar Jogo
            AddGameView()
                .tabItem {
                    Label("Adicionar", systemImage: "plus.circle.fill")
                }

            // Aba 3: Sobre
            AboutView()
                .tabItem {
                    Label("Sobre", systemImage: "info.circle.fill")
                }
        }
        // Adiciona a visualização acessória à TabView.
        .tabViewBottomAccessory {
            GameStatsAccessoryView()
        }
        // Habilita o comportamento de minimizar a barra ao rolar.
        // Isso acionará a mudança no `tabViewBottomAccessoryPlacement`.
        .tabBarMinimizeBehavior(.onScrollDown)
        // Fornece o dataLoader para as views filhas que precisam dele.
        .environmentObject(dataLoader)
    }
}


#Preview {
    ContentView()
}

