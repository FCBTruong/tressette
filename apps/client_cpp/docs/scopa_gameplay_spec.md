# Scopa 2P Gameplay Spec

## 1. Tong quan

Scopa la game bai capture su dung bo bai Y 40 la. Tran dau offline 2 nguoi gom:

- Player
- Bot

Muc tieu la bat bai tren ban de ghi diem theo 5 nhom:

- Carte
- Denari
- Settebello
- Primiera
- Scope

Match mac dinh danh den 11 diem. Moi round tinh diem rieng, sau do cong vao diem match.

## 2. Bo bai va gia tri

Bo bai gom 40 la.

- 4 chat: Denari, Coppe, Spade, Bastoni
- Moi chat co 10 la: A, 2, 3, 4, 5, 6, 7, Fante, Cavallo, Re

Gia tri capture:

- A = 1
- 2 = 2
- 3 = 3
- 4 = 4
- 5 = 5
- 6 = 6
- 7 = 7
- Fante = 8
- Cavallo = 9
- Re = 10

Gia tri Primiera:

- 7 = 21
- 6 = 18
- A = 16
- 5 = 15
- 4 = 14
- 3 = 13
- 2 = 12
- Fante = 10
- Cavallo = 10
- Re = 10

## 3. Mapping card id

De thong nhat voi Tressette, card id giu nguyen:

- `suit = id % 4`
- `rank = id / 4 + 1`

Thu tu suit de xuat:

- 0 = Denari
- 1 = Coppe
- 2 = Spade
- 3 = Bastoni

Vi du:

- `id = 0` -> A Denari
- `id = 4` -> 2 Denari
- `id = 24` -> 7 Denari

## 4. Setup dau van

Moi round:

1. Xao bo bai 40 la.
2. Chia moi nguoi 3 la.
3. Lat 4 la ngua len ban.
4. Phan con lai la deck.
5. Chon nguoi di dau:

- De xuat: nguoi chia bai luan phien theo round
- Nguoi di dau = nguoi khong chia

Phien ban don gian bo qua cac local rule dac biet cua 4 la mo dau.

## 5. Luot choi co ban

Moi turn:

1. Nguoi choi chon 1 la tren tay.
2. He thong tinh cac capture option hop le.
3. Neu co capture hop le, nguoi choi phai bat.
4. Neu khong co capture hop le, la vua danh duoc dat len ban.
5. Turn chuyen sang doi thu.

Khi ca hai nguoi het 3 la tren tay:

- Neu deck con bai: chia tiep moi nguoi 3 la
- Khong lat them bai ra ban
- Nguoi di dau van la starter cua round

Khi deck het va ca hai cung het bai tren tay:

- Round ket thuc
- Bai con tren ban duoc giao cho nguoi capture cuoi cung

## 6. Luat bat bai

Khi danh 1 la co gia tri `X`:

1. Neu tren ban co mot hoac nhieu la don co gia tri `X`, chi duoc bat theo nhom la don nay.
2. Neu khong co la don gia tri `X`, duoc bat mot to hop nhieu la co tong bang `X`.
3. Neu co nhieu to hop hop le, nguoi choi duoc chon mot to hop.
4. La vua danh cung di vao pile da an cua nguoi choi.

Vi du:

- Danh 7, ban co 7 Coppe -> bat 7 Coppe
- Danh 7, khong co 7 tren ban, ban co 3 va 4 -> bat 3 + 4
- Danh 7, ban co A + 2 + 4 -> bat A + 2 + 4

Luật uu tien:

- Neu co ca la don cung value va to hop co tong bang value, bat buoc lay la don
- Khong duoc bo qua la don de lay to hop

## 7. Luat Scopa

Neu sau khi capture xong ma tren ban khong con la nao, nguoi choi ghi 1 Scopa.

De xuat ap dung Option A:

- Khong tinh Scopa o nuoc di cuoi cung cua round

Ly do:

- Gan luat truyen thong hon
- De predict hon cho UI va score logic

Moi Scopa duoc luu bang `scopa_count` rieng theo nguoi choi.

## 8. Last capturer

Khi round ket thuc:

- Neu tren ban con bai, toan bo bai con lai duoc trao cho `last_capturer`
- So bai nay chi cong vao pile da an
- Khong tao Scopa

Neu khong ai capture trong ca round:

- Co the bo qua rule nay trong implementation don gian
- Truong hop nay rat hiem

## 9. Tinh diem cuoi round

### A. Carte

- Ai co nhieu la da an hon duoc 1 diem
- Hoa thi khong ai duoc diem

### B. Denari

- Ai co nhieu la Denari hon duoc 1 diem
- Hoa thi khong ai duoc diem

### C. Settebello

- Nguoi so huu 7 Denari duoc 1 diem

### D. Primiera

- Moi chat lay 1 la co gia tri Primiera cao nhat
- Chi hop le neu nguoi choi co it nhat 1 la o moi chat
- So tong 4 chat nao cao hon thi duoc 1 diem
- Neu hoa thi khong ai duoc diem

### E. Scope

- Moi Scopa = 1 diem

Cong thuc:

`total_score = carte + denari + settebello + primiera + scopa_count`

## 10. Dieu kien thang match

Match mac dinh danh den 11 diem.

Sau moi round:

1. Cong diem round vao `match_score`
2. Kiem tra ket qua

Rule:

- Nguoi dau tien dat hoac vuot 11 diem va co diem cao hon doi thu se thang
- Neu ca hai cung vuot 11 sau cung mot round va bang diem, tiep tuc round phu

## 11. State machine de xuat

### InitGame

- Tao App
- Reset match score = 0
- Round number = 1

### ShuffleDeck

- Tao bo 40 la
- Tron bai

### DealInitialHands

- Chia Player 3 la
- Chia Bot 3 la

### DealInitialTable

- Lat 4 la len ban

### PlayerTurn

- Cho player chon la
- Tinh `valid_captures`
- Neu 0 option -> dat bai len ban
- Neu 1 option -> apply ngay
- Neu >1 option -> sang `ResolveCapture` theo lua chon

### BotTurn

- Bot danh gia cac move hop le
- Chon move theo heuristic
- Apply move

### ResolveCapture

- Bo la danh ra khoi hand
- Dua bai bat + la danh vao `captured_cards`
- Kiem tra co Scopa hay khong
- Cap nhat `last_capturer`

### CheckHandsEmpty

- Neu ca hai het hand:

Neu deck con bai -> `DealNextHands`

Neu deck het bai -> `EndRound`

- Neu van con hand -> doi turn

### DealNextHands

- Chia tiep moi nguoi 3 la
- Khong lat them bai tren ban
- Tro lai turn cua `starter`

### EndRound

- Neu table con bai -> giao cho `last_capturer`
- Chuyen sang `ScoreRound`

### ScoreRound

- Tinh Carte, Denari, Settebello, Primiera, Scope
- Cong vao `match_score`

### CheckMatchWinner

- Neu co nguoi thang -> `match_over = true`
- Nguoc lai -> `StartNextRound`

### StartNextRound

- Tang round number
- Luan phien dealer
- Reset round state
- Ve `ShuffleDeck`

## 12. Cau truc du lieu de xuat

### Card

```text
Card {
  id: int
  suit: Suit
  rank: int
  capture_value: int
  primiera_value: int
}
```

### PlayerState

```text
PlayerState {
  hand: vector<Card>
  captured_cards: vector<Card>
  scopa_count: int
  match_score: int
}
```

### CaptureOption

```text
CaptureOption {
  table_indices: vector<int>
  label: string
}
```

### GameState

```text
GameState {
  deck: vector<Card>
  table_cards: vector<Card>
  players[2]: PlayerState
  current_turn: int
  last_capturer: int
  phase: GamePhase
  selected_hand_index: int
  valid_captures: vector<CaptureOption>
  round_over: bool
  match_over: bool
  round_number: int
}
```

## 13. Luong choi tung buoc

1. Tao round moi va xao bai
2. Chia 3 la moi ben, 4 la ra ban
3. Nguoi di dau danh 1 la
4. Capture neu hop le, nguoc lai dat len ban
5. Doi turn
6. Het 3 la tren tay cua ca hai thi chia tiep 3 la
7. Lap lai den khi deck het va ca hai het bai
8. Giao bai con tren ban cho `last_capturer`
9. Tinh diem round
10. Cong diem match
11. Neu chua co nguoi thang, mo round moi

## 14. Vi du 3 luot capture

### Vi du 1: bat la don

- Table: 7 Coppe, 3 Bastoni, 4 Denari
- Player danh 7 Spade
- Co la don gia tri 7 tren ban
- Player phai bat 7 Coppe, khong duoc chon 3 + 4

Ket qua:

- Player an: 7 Spade + 7 Coppe
- Table con: 3 Bastoni, 4 Denari

### Vi du 2: bat to hop tong

- Table: A Coppe, 2 Bastoni, 4 Spade
- Bot danh 7 Denari
- Tren ban khong co la 7
- Co to hop A + 2 + 4 = 7

Ket qua:

- Bot an 4 la
- Bot dong thoi lay luon Settebello

### Vi du 3: tao Scopa

- Table: 3 Denari, 4 Coppe
- Player danh 7 Bastoni
- Khong co la don 7
- Co to hop 3 + 4 = 7
- Sau capture, table rong

Ket qua:

- Player +1 Scopa

## 15. Vi du tinh diem cuoi round

Gia su sau round:

- Player:

Carte = 21 la
Denari = 6 la
Settebello = co
Primiera = 78
Scope = 2

- Bot:

Carte = 19 la
Denari = 4 la
Settebello = khong
Primiera = 74
Scope = 1

Tinh diem:

- Player:

Carte 1
Denari 1
Settebello 1
Primiera 1
Scope 2
Tong = 6

- Bot:

Carte 0
Denari 0
Settebello 0
Primiera 0
Scope 1
Tong = 1

## 16. Bot AI don gian

Thu tu uu tien de xuat:

1. Nuoc tao Scopa va khong phai nuoc cuoi round
2. Nuoc lay duoc Settebello
3. Nuoc lay duoc nhieu Denari hon
4. Nuoc lay duoc nhieu la hon
5. Nuoc tang Primiera gain tot hon
6. Neu khong bat duoc, danh la it gia tri chien thuat nhat

Penalty khi danh ra ban:

- Phat cao neu la Denari
- Phat rat cao neu la 7
- Phat neu de table qua nho, de doi thu co kha nang Scopa

## 17. Edge cases can xu ly

- Nhieu capture option hop le
- Co la don bang value va co ca to hop bang tong value
- Table rong truoc turn
- Danh la khong bat duoc thi dat len ban
- Het deck nhung van con bai tren tay
- Het deck va het bai tren tay
- Bai con tren ban cuoi round
- Khong tinh Scopa o nuoc cuoi neu dung Option A
- Hoa Carte
- Hoa Denari
- Hoa Primiera
- Nguoi choi khong co du 4 chat de tinh Primiera
- Ca round khong co ai capture

## 18. Pseudocode

### getCaptureOptions(card, table_cards)

```text
function getCaptureOptions(card, table_cards):
  exactSingles = []
  for each table_index, table_card in table_cards:
    if table_card.capture_value == card.capture_value:
      exactSingles.push([table_index])

  if exactSingles is not empty:
    return buildOptions(exactSingles)

  results = []

  function dfs(start, remaining, current_indices):
    if remaining == 0 and current_indices not empty:
      results.push(copy(current_indices))
      return
    if remaining < 0:
      return

    for i from start to table_cards.size - 1:
      value = table_cards[i].capture_value
      if value <= remaining:
        current_indices.push(i)
        dfs(i + 1, remaining - value, current_indices)
        current_indices.pop()

  dfs(0, card.capture_value, [])
  return buildOptions(results)
```

### applyMove(player, played_card, selected_capture)

```text
function applyMove(player, played_card, selected_capture):
  remove played_card from player.hand

  if selected_capture exists:
    add played_card to player.captured_cards
    for each table_index in selected_capture.table_indices descending:
      add table_cards[table_index] to player.captured_cards
      remove table_cards[table_index] from table

    last_capturer = player

    if table_cards is empty and not isFinalPlayOfRound():
      player.scopa_count += 1
  else:
    table_cards.push(played_card)

  current_turn = other_player
```

### checkScopa()

```text
function checkScopa(table_cards, is_final_play):
  if table_cards.empty and not is_final_play:
    return true
  return false
```

### dealNextHands()

```text
function dealNextHands():
  deal 3 cards to player
  deal 3 cards to bot
  sort both hands
  current_turn = starter
```

### scoreRound()

```text
function scoreRound(game_state):
  score = new RoundScoreBreakdown()

  if player.captured_cards.size > bot.captured_cards.size:
    score.carte[player] = 1
  else if bot bigger:
    score.carte[bot] = 1

  if countDenari(player) > countDenari(bot):
    score.denari[player] = 1
  else if bot bigger:
    score.denari[bot] = 1

  if player has 7 Denari:
    score.settebello[player] = 1
  if bot has 7 Denari:
    score.settebello[bot] = 1

  playerPrimieraEligible, playerPrimiera = computePrimiera(player)
  botPrimieraEligible, botPrimiera = computePrimiera(bot)

  if playerPrimieraEligible or botPrimieraEligible:
    if playerPrimiera > botPrimiera:
      score.primiera[player] = 1
    else if botPrimiera > playerPrimiera:
      score.primiera[bot] = 1

  score.scope[player] = player.scopa_count
  score.scope[bot] = bot.scopa_count

  score.total[player] = carte + denari + settebello + primiera + scope
  score.total[bot] = carte + denari + settebello + primiera + scope

  player.match_score += score.total[player]
  bot.match_score += score.total[bot]

  return score
```

### chooseBotMove()

```text
function chooseBotMove(bot_hand, table_cards):
  best_move = null
  best_score = -infinity

  for each card in bot_hand:
    options = getCaptureOptions(card, table_cards)

    if options empty:
      score = -discardRisk(card, table_cards)
      update best if score better
      continue

    for each option in options:
      score = 0
      if option clears table and not final_play:
        score += huge_bonus
      if option takes settebello:
        score += very_large_bonus
      score += option.denari_count * denari_weight
      score += option.captured_count * cards_weight
      score += option.primiera_gain * primiera_weight
      update best if score better

  return best_move
```

## 19. Ghi chu implementation UI

- Reuse card asset path va card id mapping cua Tressette
- Player hand face up, bot hand face down
- Table cards luon face up
- Neu player chon la co nhieu capture option, hien panel option de chon
- Sau round, hien scoreboard overlay
- Match over thi cho `New Match` hoac `Lobby`
