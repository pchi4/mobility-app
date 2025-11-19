# 🚘 Mobility App — Plataforma de Mobilidade Full-Stack (Flutter + NestJS)

Aplicativo e backend completos para uma solução de mobilidade urbana inspirada em plataformas como **99 Pop** e **Uber**.  
A proposta é fornecer uma base escalável e segura que possa ser **licenciada ou personalizada** por empresas e órgãos que desejem operar serviços de transporte sob demanda.

---

## 🧭 Visão Geral

**Arquitetura:**  
- **Frontend:** Flutter (iOS/Android)  
- **Backend:** NestJS (REST + WebSocket)  
- **Banco de Dados:** PostgreSQL + PostGIS  
- **Infraestrutura:** Docker / Redis / Kubernetes  

**Objetivo do MVP:**  
- Permitir login/cadastro de **passageiros e motoristas**.  
- Gerenciar **corridas em tempo real** via WebSocket.  
- Exibir **mapa, estimativa de preço e histórico de viagens**.  
- Oferecer **tema claro/escuro**, **autenticação segura** e **UX responsiva**.

---

## 🧩 Funcionalidades do MVP

| Módulo | Descrição |
|--------|------------|
| **A-1 Splash / Onboarding** | Tela de splash animada + 3 cards introdutórios com ilustrações e CTA (Entrar / Criar conta / Pular). |
| **A-2 Login & Cadastro** | Formulários separados para Passageiro e Motorista. Campos: nome, e-mail, telefone (OTP opcional), senha e role. Login social (Google/Apple) e botão para alternar tema (Dark/Light). |
| **A-3 Home (Passageiro)** | Mapa full-screen (Google Maps / Mapbox) com motoristas próximos, barra de busca e botões rápidos. |
| **A-4 Requisição de Corrida** | Seleção de categoria (Pop, Comfort, Taxi), preview de preço e ETA, comunicação via WebSocket. |
| **A-5 Corrida em Andamento** | Acompanhamento do trajeto com mapa dinâmico, card com dados do motorista e botões SOS/Cancelar. |
| **A-6 Pós-Corrida & Avaliação** | Avaliação por estrelas, comentário e gorjeta. |
| **A-7 Menu / Perfil** | Perfil do usuário, documentos (motorista), histórico e preferências (tema, pagamento). |
| **B-1 a B-4 (Motorista)** | Home com modo Online/Offline, aceite de corridas, acompanhamento em tempo real e upload de documentos (CNH/CRLV). |

---

## ⚙️ Stack Técnica (Mobile)

| Categoria | Pacotes / Tecnologias |
|------------|-----------------------|
| UI / Navegação | `flutter`, `go_router` ou `auto_route` |
| Estado | `flutter_riverpod` |
| Autenticação | `firebase_auth`, `google_sign_in`, `sign_in_with_apple` |
| Armazenamento Seguro | `flutter_secure_storage` |
| Mapa | `google_maps_flutter` ou `mapbox_gl` |
| Localização | `geolocator`, `background_locator_2` |
| WebSocket | `socket_io_client` |
| Upload | `dio` (para upload S3 com presigned URL) |
| Tema | `ThemeController` com alternância Dark/Light |
| Permissões | `permission_handler` |
