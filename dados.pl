:- encoding(utf8).

% Dinamicos
:- dynamic fornecedor/4.
:- dynamic produto/6.
:- dynamic cultura/3.
:- dynamic campanha/5.
:- dynamic colheita/4.
:- dynamic cliente/5.
:- dynamic venda/5.
:- dynamic item_venda/5.

% Fornecedores
fornecedor(1, 'Sementes do Norte Lda', sementes, '842000001').
fornecedor(2, 'AgroMaq Nampula', maquinaria, '842000002').
fornecedor(3, 'Fertiliza Cabo Delgado', fertilizantes, '842000003').

% Produtos (ID 4 inexistente de proposito)
produto(1, 'Semente Milho Matuba 5kg', semente, 350, 100, 1).
produto(2, 'Semente Mandioca 10kg', semente, 500, 50, 1).
produto(3, 'Tractor 75CV', maquinaria, 1500000, 2, 2).
produto(5, 'Fertilizante NPK 50kg', fertilizante, 2200, 80, 3).
produto(6, 'Ureia 50kg', fertilizante, 1800, 60, 3).

% Culturas
cultura(1, milho, 'Matuba').
cultura(2, mandioca, 'Nacional').
cultura(3, arroz, 'Chokwe').

% Campanhas
campanha(1, 2024, 1, 5.0, 8000).
campanha(2, 2024, 2, 3.0, 6000).
campanha(3, 2024, 3, 2.0, 3500).

% Colheitas (2 por campanha, somando os totais dados)
% Campanha 1: 7500 kg -> 4000 + 3500
colheita(1, 1, '2024-03-15', 4000).
colheita(2, 1, '2024-03-20', 3500).

% Campanha 2: 5800 kg -> 3000 + 2800
colheita(3, 2, '2024-04-10', 3000).
colheita(4, 2, '2024-04-15', 2800).

% Campanha 3: 3200 kg -> 1700 + 1500
colheita(5, 3, '2024-05-01', 1700).
colheita(6, 3, '2024-05-05', 1500).

% Cliente inicial
cliente(1, 'João Silva', joao, 1234, 500000).
cliente(2, 'Tahir', tohas, 1007, 100000).
cliente(3, 'Allanah', lanahctrl, 2205, 1000000).