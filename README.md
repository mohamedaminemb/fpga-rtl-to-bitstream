# FPGA RTL to Bitstream

[![VHDL Simulation](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml/badge.svg?branch=main)](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml)

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt rassemble les sources RTL, leurs testbenches auto-vérifiants et une régression Python exécutée localement et automatiquement avec GitHub Actions.

## État actuel

| Module | Fonction | Configuration testée | Vérifications |
|---|---|---|---:|
| `mux21` | Multiplexeur combinatoire 2 vers 1 | Entrées binaires | 8 |
| `adder_sub` | Additionneur/soustracteur non signé | `N = 8` | 4 |
| `reg_en` | Registre avec reset et enable | `WIDTH = 8` | 7 |
| `counter_en` | Compteur avec reset et enable | `WIDTH = 3` | 14 |
| `clock_enable` | Autorisation périodique | `DIVISOR = 4` | 16 |
| `edge_detector` | Détecteur de montée échantillonnée | Entrée synchrone d’un bit | 10 |
| `sync_2ff` | Synchroniseur à deux bascules | Entrée d’un bit | 13 |
| `debouncer` | Filtre anti-rebond | `STABLE_CYCLES = 3` | 25 |
| `button_conditioner` | Traitement complet de bouton | `STABLE_CYCLES = 3` | 88 |
| `sequence_detector` | Détection de `1011` avec chevauchement | Flux binaire synchrone | 46 |
| `traffic_light_controller` | FSM de feu tricolore temporisé | Durées `(3,4,2)` et `(1,1,1)` | 68 |
| `fifo_sync` | FIFO synchrone à lecture enregistrée | `WIDTH = 8`, `DEPTH = 4` | 93 |
| `uart_tx` | Émetteur UART 8N1 | `CLKS_PER_BIT = 4` | 180 |
| `uart_rx` | Récepteur UART 8N1 | `CLKS_PER_BIT = 8` | 26 |
| **Total** | **14 testbenches** | | **598** |

La régression locale des quatorze testbenches a réussi avec un code de retour égal à `0`. Le badge indique le résultat du workflow publié sur la branche `main`.

Le bouclage UART, la synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte restent à réaliser.

## Prérequis

- Python 3
- GHDL avec prise en charge de VHDL-2008
- GTKWave, facultatif, pour examiner les chronogrammes

Le script utilise uniquement la bibliothèque standard Python.

Environnement de développement : Ubuntu 24.04 LTS, VS Code avec TerosHDL, Git et GitHub.

```bash
python3 --version
ghdl --version
gtkwave --version
```

## Organisation du dépôt

```text
fpga-rtl-to-bitstream/
├── .github/
│   └── workflows/
│       └── simulation.yml
├── .gitignore
├── README.md
├── vhdl_ls.toml
├── rtl/
│   ├── mux21.vhd
│   ├── adder_sub.vhd
│   ├── reg_en.vhd
│   ├── counter_en.vhd
│   ├── clock_enable.vhd
│   ├── edge_detector.vhd
│   ├── sync_2ff.vhd
│   ├── debouncer.vhd
│   ├── button_conditioner.vhd
│   ├── sequence_detector.vhd
│   ├── traffic_light_controller.vhd
│   ├── fifo_sync.vhd
│   ├── uart_tx.vhd
│   └── uart_rx.vhd
├── tb/
│   ├── tb_mux21.vhd
│   ├── tb_adder_sub.vhd
│   ├── tb_reg_en.vhd
│   ├── tb_counter_en.vhd
│   ├── tb_clock_enable.vhd
│   ├── tb_edge_detector.vhd
│   ├── tb_sync_2ff.vhd
│   ├── tb_debouncer.vhd
│   ├── tb_button_conditioner.vhd
│   ├── tb_sequence_detector.vhd
│   ├── tb_traffic_light_controller.vhd
│   ├── tb_fifo_sync.vhd
│   ├── tb_uart_tx.vhd
│   └── tb_uart_rx.vhd
└── scripts/
    └── run_tests.py
```

- `rtl/` : descriptions matérielles destinées à la synthèse.
- `tb/` : bancs de test de simulation.
- `scripts/` : automatisation de la régression.
- `.github/workflows/` : intégration continue.
- `vhdl_ls.toml` : configuration de l’analyseur VHDL de l’éditeur.

## Lancer la régression

Depuis la racine du dépôt :

```bash
python3 scripts/run_tests.py
```

Pour chaque module, le script analyse les sources, élabore le testbench et lance la simulation avec `--assert-level=error`.

Il s’arrête dès qu’une commande échoue et transmet son code de retour.

Message final attendu :

```text
All 14 testbenches passed.
```

Pour consulter le code de retour immédiatement après l’exécution :

```bash
echo $?
```

Un code `0` indique la réussite.

Le script doit être exécuté depuis la racine du dépôt. Il ne génère pas de traces VCD. Les composants sont analysés avant les modules d’intégration qui les utilisent.

## Intégration continue

Le workflow **VHDL Simulation** s’exécute à chaque push, lors des événements de pull request couverts par son déclencheur et à la demande avec **Run workflow**.

Sur une machine GitHub sous Ubuntu 24.04, il :

1. Récupère le dépôt.
2. Installe GHDL et Python 3.
3. Affiche leurs versions.
4. Exécute la régression Python.

Le workflow possède un accès en lecture au contenu du dépôt et une limite d’exécution de 10 minutes.

Les journaux sont disponibles dans l’onglet [Actions](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml).

La CI réalise actuellement la vérification RTL. La synthèse et la validation matérielle restent à intégrer au flot.

## Composants de base

### `mux21`

Multiplexeur combinatoire : `y = a` lorsque `sel = '0'`, sinon `y = b`.

Les huit combinaisons binaires sont vérifiées. Une modification temporaire d’un résultat attendu a également confirmé la détection d’erreur par assertion.

### `adder_sub`

Additionneur/soustracteur non signé de `N` bits :

- `sub = '0'` : addition.
- `sub = '1'` : soustraction.

Les calculs utilisent `unsigned` et `numeric_std`. Le résultat est conservé sur `N` bits, modulo `2^N`, sans sortie de retenue ni indicateur de dépassement.

Les tests sur 8 bits vérifient les opérations `15 + 10`, `25 - 10`, `5 - 10` et `200 + 100`, avec les résultats attendus `25`, `15`, `251` et `44`.

### `reg_en`

Registre de `WIDTH` bits avec reset synchrone actif à l’état haut, prioritaire sur l’enable.

Au front montant, il charge l’entrée si `en = '1'`, sinon conserve sa valeur.

### `counter_en`

Compteur non signé de `WIDTH` bits, avec reset synchrone prioritaire et enable.

Le comptage s’effectue modulo `2^WIDTH`. La valeur maximale revient à zéro lors d’une nouvelle incrémentation.

### `clock_enable`

Produit une autorisation `tick` pendant un cycle tous les `DIVISOR` cycles.

Pour `DIVISOR = 4`, après reset :

```text
Cycle :  1 2 3 4 5 6 7 8
tick  :  0 0 0 1 0 0 0 1
```

Le reset synchrone recommence le comptage à zéro. `tick` est destiné à être utilisé comme enable dans une logique cadencée par `clk`.

### `edge_detector`

Détecte une montée entre deux échantillons successifs d’une entrée synchrone :

```text
rise_pulse suivant = NON previous ET sig_in
previous suivant   = sig_in
```

La sortie est enregistrée. Le reset remet les deux mémoires à zéro.

Une entrée haute au premier front hors reset produit une impulsion. Une transition complète entre deux observations peut ne pas être détectée.

### `sync_2ff`

Deux bascules successives échantillonnent une entrée d’un bit :

```text
async_in → stage1 → sync_out
```

Au front montant :

```text
stage1 suivant   = async_in
sync_out suivant = ancien stage1
```

Le reset synchrone remet les deux bascules à zéro.

Le module ne garantit pas la capture d’impulsions brèves et ne constitue pas une solution générale pour un bus multibit.

La simulation RTL ne reproduit pas la métastabilité physique. Les attributs FPGA, le placement et les contraintes seront traités lors de l’implémentation.

### `debouncer`

Accepte une nouvelle valeur après `STABLE_CYCLES` observations consécutives différentes de la sortie actuelle. L’entrée doit être déjà synchronisée.

- Entrée égale à la sortie : annuler l’attente.
- Entrée différente : compter les observations.
- Dernière observation requise : accepter l’entrée.
- Reset : remettre sortie et compteur à zéro.

Pour trois observations :

```text
Entrée :  1 0 1 1 1 0 1
Sortie :  0 0 0 0 1 1 1
```

## Traitement du bouton — `button_conditioner`

```text
button_in → sync_2ff → debouncer → edge_detector → press_pulse
                          │
                          └──────────────────────→ button_clean
```

Les composants partagent la même horloge et le même reset synchrone. Le paramètre `STABLE_CYCLES` est transmis à l’anti-rebond.

Le détecteur observe la montée filtrée au front suivant. Les tests couvrent les appuis propres, le maintien, le relâchement et les rebonds simulés.

Une entrée maintenue haute après reset est interprétée comme un appui une fois synchronisée et filtrée.

## Détecteur de séquence — `sequence_detector`

FSM recevant un bit synchrone à chaque front montant et détectant `1011`, avec chevauchement.

Les états mémorisent les préfixes utiles : aucun préfixe, `1`, `10` et `101`.

```text
Entrée    : 1 0 1 1 0 1 1
Détection : 0 0 0 1 0 0 1
```

La détection est enregistrée au front recevant le dernier bit du motif. Le retour à l’état correspondant à `1` permet le chevauchement.

Les tests couvrent les détections, les séquences incorrectes, les suffixes utiles et le reset pendant une reconnaissance partielle.

## Contrôleur temporisé — `traffic_light_controller`

FSM de Moore commandant la rotation rouge, vert, orange.

| État | Rouge | Vert | Orange | Durée par défaut |
|---|---|---|---|---:|
| `S_RED` | 1 | 0 | 0 | 3 cycles |
| `S_GREEN` | 0 | 1 | 0 | 4 cycles |
| `S_YELLOW` | 0 | 0 | 1 | 2 cycles |

Un compteur partagé mesure la durée de chaque état et revient à zéro à chaque transition.

Le reset synchrone impose le rouge et remet le compteur à zéro.

Les configurations `(3,4,2)` et `(1,1,1)` sont testées en parallèle. Les durées sont exprimées en cycles pour la simulation.

## FIFO synchrone — `fifo_sync`

File respectant l’ordre First In, First Out, paramétrable en largeur et profondeur.

La lecture est enregistrée. Sans lecture acceptée, `data_out` conserve sa valeur.

Les demandes sont acceptées selon l’occupation avant le front montant :

| État avant deux demandes simultanées | Écriture | Lecture |
|---|---|---|
| Vide | Acceptée | Refusée |
| Occupation intermédiaire | Acceptée | Acceptée |
| Pleine | Refusée | Acceptée |

Le reset synchrone remet les pointeurs, l’occupation et la sortie à zéro sans effacer le tableau mémoire.

Les tests couvrent l’ordre des données, les limites pleine/vide, les pointeurs circulaires, les opérations simultanées et le reset d’une FIFO pleine avec demandes actives.

## Émetteur UART — `uart_tx`

Émetteur série au format 8N1 :

```text
Repos | Start | b0 b1 b2 b3 b4 b5 b6 b7 | Stop
  1   |   0   |       LSB d’abord        |  1
```

### Interface et comportement

- `CLKS_PER_BIT` : nombre de cycles par bit.
- `start` : demande acceptée uniquement dans `IDLE`.
- `data_in` : octet copié lors de l’acceptation.
- `tx` : ligne série enregistrée.
- `busy` : actif pendant toute la trame.
- `done` : impulsion d’un cycle après la durée complète du stop.

Les demandes présentées uniquement pendant la transmission sont ignorées. Une demande maintenue jusqu’au retour dans `IDLE` peut déclencher un nouvel envoi.

Le reset synchrone interrompt la trame et remet la ligne au repos.

### Vérification

Les tests contrôlent une trame complète de `0xA6`, la durée des bits, la copie de l’octet, les demandes pendant `busy`, l’impulsion `done` et une transmission de `0x00` interrompue par reset.

Les autres octets, paramètres et positions d’interruption restent à tester.

## Récepteur UART — `uart_rx`

Récepteur série 8N1 avec synchronisation d’entrée et échantillonnage près du milieu des bits.

### Interface

| Élément | Rôle |
|---|---|
| `CLKS_PER_BIT` | Nombre de cycles par bit |
| `rx` | Entrée série extérieure |
| `data_out` | Dernier octet reçu avec stop valide |
| `valid` | Impulsion d’un cycle lors d’une réception valide |
| `frame_error` | Impulsion d’un cycle si le stop est incorrect |
| `rst` | Reset synchrone actif à l’état haut |

Cette implémentation exige un `CLKS_PER_BIT` pair, supérieur ou égal à 4. Une assertion vérifie cette contrainte.

### Fonctionnement

Deux bascules synchronisent l’entrée et sont remises à un au reset, conformément au niveau de repos UART.

La FSM comporte cinq états :

| État | Action |
|---|---|
| `IDLE` | Rechercher un début de start |
| `START_BIT` | Vérifier le niveau bas près du milieu du start |
| `DATA_BITS` | Échantillonner les huit bits, LSB d’abord |
| `STOP_BIT` | Vérifier le stop et publier le résultat |
| `WAIT_IDLE` | Attendre un retour au niveau haut après une erreur |

Un faux start est ignoré sans publier de donnée ni d’erreur de stop.

Si le stop vaut un, l’octet est publié avec `valid`. Sinon, `frame_error` est activé et `data_out` conserve le dernier octet valide.

La réception est annoncée au contrôle du milieu du stop ; le RX n’attend pas sa fin complète.

### Récupération après erreur

Le test de réception après erreur a révélé qu’un retour direct dans `IDLE` pouvait interpréter la fin d’un stop incorrect comme un nouveau start.

L’état `WAIT_IDLE` empêche cette nouvelle détection tant que l’entrée synchronisée reste basse.

### Vérification indépendante

Le testbench génère directement la ligne série, sans utiliser `uart_tx`. Le début des trames est décalé par rapport à l’horloge du récepteur.

Les 26 vérifications couvrent :

- Le reset initial.
- Une réception valide de `0xA6`.
- La durée de l’impulsion `valid`.
- Un faux start bref.
- Une trame `0x53` avec stop incorrect.
- La conservation du dernier octet valide.
- Le comptage de l’erreur.
- Une nouvelle réception valide après l’erreur, sans reset.

Le bilan attendu est de deux octets valides et une erreur de trame. Le chronogramme a été inspecté.

## Paramétrage du lien UART

```text
Durée d’un bit = CLKS_PER_BIT × période de clk
Baudrate = fréquence de clk / CLKS_PER_BIT
```

Les tests individuels TX et RX utilisent des paramètres différents et sont indépendants.

Pour les connecter, leurs durées de bit doivent correspondre. Avec la même horloge, ils doivent utiliser la même valeur de `CLKS_PER_BIT`.

Le bouclage prévu utilisera initialement `CLKS_PER_BIT = 8` pour les deux modules.

## Simulations individuelles

Depuis la racine du dépôt :

```bash
ghdl -a --std=08 rtl/uart_rx.vhd tb/tb_uart_rx.vhd
ghdl -e --std=08 tb_uart_rx
ghdl -r --std=08 tb_uart_rx --assert-level=error --vcd=uart_rx.vcd
```

Pour un autre composant indépendant, remplacer les noms du module et du testbench.

Pour l’intégration du bouton, analyser ses dépendances avant le module parent :

```bash
ghdl -a --std=08 rtl/sync_2ff.vhd rtl/debouncer.vhd rtl/edge_detector.vhd rtl/button_conditioner.vhd tb/tb_button_conditioner.vhd
ghdl -e --std=08 tb_button_conditioner
ghdl -r --std=08 tb_button_conditioner --assert-level=error --vcd=button_conditioner.vcd
```

### Résultats attendus

| Testbench | Vérifications | Dernière vérification ou fin |
|---|---:|---|
| `tb_mux21` | 8 | 80 ns |
| `tb_adder_sub` | 4 | 40 ns |
| `tb_reg_en` | 7 | 46 ns |
| `tb_counter_en` | 14 | 126 ns |
| `tb_clock_enable` | 16 | 156 ns |
| `tb_edge_detector` | 10 | 86 ns |
| `tb_sync_2ff` | 13 | 106 ns |
| `tb_debouncer` | 25 | 246 ns |
| `tb_button_conditioner` | 88 | 436 ns |
| `tb_sequence_detector` | 46 | 466 ns |
| `tb_traffic_light_controller` | 68 | 326 ns |
| `tb_fifo_sync` | 93 | 296 ns |
| `tb_uart_tx` | 180 | 586 ns |
| `tb_uart_rx` | 26 | 2807 ns |

Après génération d’une trace :

```bash
gtkwave uart_rx.vcd
```

## Configuration de l’éditeur

Le fichier `vhdl_ls.toml` associe les sources et testbenches à une bibliothèque commune :

```toml
standard = "2008"

[libraries]
defaultlib.files = [
    "rtl/*.vhd",
    "tb/*.vhd",
]
```

Cette configuration est indépendante de la compilation GHDL du script Python.

## Limites de vérification

Les 598 vérifications sont des comparaisons exécutées dans des scénarios dirigés. Elles ne constituent pas une mesure de couverture de code ou de couverture fonctionnelle.

Extensions prévues :

- Plusieurs paramètres pour les composants génériques.
- FIFO de profondeur 1 et de profondeur non puissance de deux.
- Cas limites des générateurs et filtres.
- Autres octets et réceptions UART consécutives.
- Autres phases de départ et écarts de baudrate.
- Reset du RX pendant une réception.
- Modèles de référence et scénarios aléatoires.

Les tests utilisent principalement des valeurs binaires. La métastabilité physique, les délais matériels et la fiabilité sur carte ne sont pas évalués par ces simulations RTL.

L’arrêt au premier échec de la régression a été contrôlé par injection temporaire d’un résultat attendu incorrect dans le testbench du multiplexeur.

## Fichiers générés

Les fichiers de travail GHDL et les traces sont produits localement et exclus du dépôt par `.gitignore`, notamment :

```gitignore
*.cf
*.vcd
*.o
```

Le dépôt conserve les sources, les testbenches, les scripts et la documentation nécessaires pour reproduire les simulations.

## Prochaines étapes

- Bouclage UART TX vers RX
- Vérification de 256 octets pseudo-aléatoires
- Extension des tests aux cas limites et à plusieurs paramètres
- Vérification structurée avec VUnit ou cocotb
- Intégration FIFO et UART
- Système pilotable par commandes UART
- Synthèse, contraintes et analyse de timing
- Génération du bitstream et validation sur carte FPGA