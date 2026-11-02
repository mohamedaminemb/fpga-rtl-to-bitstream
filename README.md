# FPGA RTL to Bitstream

[![VHDL Simulation](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml/badge.svg?branch=main)](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml)

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt rassemble les sources RTL, les testbenches auto-vérifiants et une régression Python exécutée localement et automatiquement avec GitHub Actions.

## État actuel

Le projet contient **14 modules RTL et 15 testbenches**.

Les tests des composants regroupent **598 vérifications dirigées**. Un test d’intégration supplémentaire vérifie la transmission et la réception de **256 octets pseudo-aléatoires en bouclage UART**.

| Module | Fonction | Configuration testée | Vérifications dirigées |
|---|---|---|---:|
| `mux21` | Multiplexeur combinatoire | Entrées binaires | 8 |
| `adder_sub` | Additionneur/soustracteur non signé | `N = 8` | 4 |
| `reg_en` | Registre avec reset et enable | `WIDTH = 8` | 7 |
| `counter_en` | Compteur avec reset et enable | `WIDTH = 3` | 14 |
| `clock_enable` | Autorisation périodique | `DIVISOR = 4` | 16 |
| `edge_detector` | Détecteur de montée échantillonnée | Entrée synchrone d’un bit | 10 |
| `sync_2ff` | Synchroniseur à deux bascules | Entrée d’un bit | 13 |
| `debouncer` | Filtre anti-rebond | `STABLE_CYCLES = 3` | 25 |
| `button_conditioner` | Traitement complet de bouton | `STABLE_CYCLES = 3` | 88 |
| `sequence_detector` | Détecteur de `1011` avec chevauchement | Flux binaire synchrone | 46 |
| `traffic_light_controller` | FSM temporisée | Durées `(3,4,2)` et `(1,1,1)` | 68 |
| `fifo_sync` | FIFO à lecture enregistrée | `WIDTH = 8`, `DEPTH = 4` | 93 |
| `uart_tx` | Émetteur UART 8N1 | `CLKS_PER_BIT = 4` | 180 |
| `uart_rx` | Récepteur UART 8N1 | `CLKS_PER_BIT = 8` | 26 |

| Test d’intégration | Configuration | Résultat |
|---|---|---|
| `tb_uart_loopback` | TX et RX avec `CLKS_PER_BIT = 8` | 256 octets pseudo-aléatoires correctement reçus |

La régression locale des quinze testbenches a réussi avec un code de retour égal à `0`. Le badge indique le résultat du workflow publié sur la branche `main`.

La synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte restent à réaliser.

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
│   ├── tb_uart_rx.vhd
│   └── tb_uart_loopback.vhd
└── scripts/
    └── run_tests.py
```

Le bouclage est réalisé dans le testbench : il n’existe pas de module `rtl/uart_loopback.vhd`.

## Lancer la régression

Depuis la racine du dépôt :

```bash
python3 scripts/run_tests.py
```

Pour chaque testbench, le script analyse les sources, élabore l’entité de test et lance la simulation avec `--assert-level=error`.

Il s’arrête dès qu’une commande échoue et transmet son code de retour.

Message final attendu :

```text
All 15 testbenches passed.
```

Pour consulter le code de retour immédiatement après l’exécution :

```bash
echo $?
```

Un code `0` indique la réussite.

Le script doit être exécuté depuis la racine du dépôt. Il ne génère pas de traces VCD.

Les dépendances sont analysées avant les modules qui les instancient. Le dictionnaire `source_overrides` indique les sources particulières du test de bouclage UART.

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

## Composants fondamentaux

### `mux21`

Multiplexeur combinatoire : `y = a` lorsque `sel = '0'`, sinon `y = b`.

Les huit combinaisons binaires sont vérifiées. Une modification temporaire d’un résultat attendu a également confirmé la détection d’erreur par assertion.

### `adder_sub`

Additionneur/soustracteur non signé de `N` bits utilisant `numeric_std`.

Le résultat est conservé sur `N` bits, modulo `2^N`, sans sortie de retenue ni indicateur de dépassement.

Les tests sur 8 bits vérifient les additions, les soustractions et le comportement modulo 256.

### `reg_en`

Registre de `WIDTH` bits avec reset synchrone actif à l’état haut, prioritaire sur l’enable.

Au front montant, il charge l’entrée si l’enable est actif, sinon conserve sa valeur.

### `counter_en`

Compteur non signé de `WIDTH` bits, avec reset synchrone prioritaire et enable.

Le comptage s’effectue modulo `2^WIDTH`. Les tests couvrent notamment le maintien et le débordement.

### `clock_enable`

Produit une autorisation pendant un cycle tous les `DIVISOR` cycles.

```text
DIVISOR = 4
Cycle :  1 2 3 4 5 6 7 8
tick  :  0 0 0 1 0 0 0 1
```

La sortie est destinée à être utilisée comme enable dans une logique cadencée par la même horloge.

### `edge_detector`

Détecte une montée entre deux échantillons successifs :

```text
rise_pulse suivant = NON previous ET sig_in
previous suivant   = sig_in
```

La sortie est enregistrée. Une entrée haute au premier front hors reset produit une impulsion, car le reset initialise l’échantillon précédent à zéro.

### `sync_2ff`

Synchroniseur d’un bit à deux bascules :

```text
async_in → stage1 → sync_out
```

Le reset synchrone remet les deux bascules à zéro.

Le module ne garantit pas la capture d’impulsions brèves et ne constitue pas une solution générale pour un bus multibit.

La simulation RTL ne reproduit pas la métastabilité physique. Les attributs FPGA, le placement et les contraintes seront traités lors de l’implémentation.

### `debouncer`

Accepte une nouvelle valeur après `STABLE_CYCLES` observations consécutives différentes de la sortie actuelle. L’entrée doit être déjà synchronisée.

Le retour de l’entrée à la valeur filtrée annule l’attente. Les tests couvrent les changements courts, les rebonds et le reset pendant l’attente.

## Traitement du bouton — `button_conditioner`

```text
button_in → sync_2ff → debouncer → edge_detector → press_pulse
                          │
                          └──────────────────────→ button_clean
```

Les composants partagent la même horloge et le même reset synchrone.

Le détecteur observe la montée filtrée au front suivant. Les tests couvrent les appuis, le maintien, le relâchement et les rebonds numériques simulés.

Une entrée maintenue haute après reset est interprétée comme un appui une fois synchronisée et filtrée.

## Détecteur de séquence — `sequence_detector`

FSM recevant un bit synchrone par front montant et détectant `1011`, avec chevauchement.

Les états mémorisent les préfixes utiles : aucun préfixe, `1`, `10` et `101`.

```text
Entrée    : 1 0 1 1 0 1 1
Détection : 0 0 0 1 0 0 1
```

Les tests couvrent les détections, les séquences incorrectes, les suffixes utiles et un reset pendant une reconnaissance partielle.

## Contrôleur temporisé — `traffic_light_controller`

FSM de Moore commandant la rotation rouge, vert, orange.

Les durées sont paramétrables. Un compteur partagé revient à zéro à chaque transition.

Le reset synchrone impose le rouge. Les configurations `(3,4,2)` et `(1,1,1)` sont testées en parallèle.

Les durées sont exprimées en cycles pour la simulation.

## FIFO synchrone — `fifo_sync`

File First In, First Out, paramétrable en largeur et profondeur.

La lecture est enregistrée. Sans lecture acceptée, `data_out` conserve sa valeur.

Les demandes sont acceptées selon l’occupation avant le front :

| État avant deux demandes simultanées | Écriture | Lecture |
|---|---|---|
| Vide | Acceptée | Refusée |
| Occupation intermédiaire | Acceptée | Acceptée |
| Pleine | Refusée | Acceptée |

Le reset remet les pointeurs, l’occupation et la sortie à zéro sans effacer le tableau mémoire.

Les tests couvrent l’ordre, les limites pleine/vide, le retour des pointeurs, les opérations simultanées et le reset avec demandes actives.

## Émetteur UART — `uart_tx`

Format 8N1 :

```text
Repos | Start | b0 b1 b2 b3 b4 b5 b6 b7 | Stop
  1   |   0   |       LSB d’abord        |  1
```

Une demande `start` est acceptée uniquement dans `IDLE`. L’octet est alors copié dans un registre interne.

Chaque bit dure `CLKS_PER_BIT` périodes. `busy` reste actif pendant toute la trame et `done` produit une impulsion après la durée complète du stop.

Les demandes présentées uniquement pendant la transmission sont ignorées. Une demande maintenue jusqu’au retour dans `IDLE` peut déclencher un nouvel envoi.

Le reset synchrone interrompt la trame et remet la ligne au repos.

Les tests individuels couvrent une trame de `0xA6`, les durées, la copie de l’octet, les demandes pendant `busy` et une interruption par reset.

## Récepteur UART — `uart_rx`

Récepteur 8N1 avec synchronisation d’entrée à deux bascules et échantillonnage près du milieu des bits.

Cette implémentation exige un `CLKS_PER_BIT` pair, supérieur ou égal à 4. Une assertion vérifie cette contrainte.

| État | Action |
|---|---|
| `IDLE` | Rechercher un start |
| `START_BIT` | Confirmer le niveau bas |
| `DATA_BITS` | Échantillonner les huit bits |
| `STOP_BIT` | Vérifier le stop |
| `WAIT_IDLE` | Attendre le niveau haut après une erreur |

Un faux start est ignoré.

Si le stop est valide, l’octet est publié sur `data_out` avec une impulsion `valid`. Sinon, `frame_error` est activé et la dernière donnée valide est conservée.

La réception est annoncée au contrôle du milieu du stop.

### Défaut détecté et corrigé

Le test de récupération a révélé qu’un retour direct dans `IDLE` après un stop incorrect pouvait interpréter sa fin comme un nouveau start.

L’état `WAIT_IDLE` attend maintenant le retour au niveau haut avant de rechercher une nouvelle trame.

### Vérification indépendante

Le testbench RX génère directement le signal série, indépendamment du TX.

Il vérifie une trame valide, un faux start, un stop incorrect, la conservation de la donnée et une nouvelle réception après erreur.

Le bilan attendu est de deux octets valides et une erreur de trame.

## Bouclage UART — `tb_uart_loopback`

Le testbench connecte directement les deux modules :

```text
Octet attendu → uart_tx → ligne série → uart_rx → Comparaison
```

TX et RX utilisent la même horloge et `CLKS_PER_BIT = 8`.

Le test :

1. Génère un octet pseudo-aléatoire.
2. Demande son émission.
3. Observe la réception et la fin d’émission.
4. Compare l’octet reçu à l’octet attendu.
5. Répète l’opération pour 256 octets.

Le moniteur vérifie les données et les impulsions `valid` et `done`. Les compteurs détectent les réceptions ou transmissions manquantes et supplémentaires. Toute erreur de trame interrompt le test.

Un LFSR de 16 bits, initialisé avec la graine fixe `0xACE1`, produit une suite reproductible. Les huit bits de poids faible fournissent chaque octet.

Les 256 octets pseudo-aléatoires peuvent contenir des répétitions : ce test n’est pas un parcours exhaustif des 256 valeurs possibles.

Une marge de repos est insérée entre les transmissions. Les trames consécutives sans marge et les horloges différentes restent à tester.

## Paramétrage du lien UART

```text
Durée d’un bit = CLKS_PER_BIT × période de clk
Baudrate = fréquence de clk / CLKS_PER_BIT
```

Les durées de bit doivent correspondre entre TX et RX. Avec une horloge commune, ils doivent utiliser le même `CLKS_PER_BIT`.

Les tests individuels utilisent des paramètres différents car ils sont indépendants. Le bouclage utilise 8 pour les deux modules.

## Simulations individuelles

Exemple pour le bouclage :

```bash
ghdl -a --std=08 rtl/uart_tx.vhd rtl/uart_rx.vhd tb/tb_uart_loopback.vhd
ghdl -e --std=08 tb_uart_loopback
ghdl -r --std=08 tb_uart_loopback --assert-level=error --vcd=uart_loopback.vcd
```

Message attendu :

```text
UART_LOOPBACK: all 256 pseudo-random bytes passed.
```

Pour un composant indépendant, analyser son fichier RTL et son testbench. Exemple :

```bash
ghdl -a --std=08 rtl/fifo_sync.vhd tb/tb_fifo_sync.vhd
ghdl -e --std=08 tb_fifo_sync
ghdl -r --std=08 tb_fifo_sync --assert-level=error --vcd=fifo_sync.vcd
```

Pour `button_conditioner`, analyser d’abord `sync_2ff`, `debouncer` et `edge_detector`.

### Durées simulées observées

| Testbench | Dernière vérification ou fin |
|---|---|
| `tb_mux21` | 80 ns |
| `tb_adder_sub` | 40 ns |
| `tb_reg_en` | 46 ns |
| `tb_counter_en` | 126 ns |
| `tb_clock_enable` | 156 ns |
| `tb_edge_detector` | 86 ns |
| `tb_sync_2ff` | 106 ns |
| `tb_debouncer` | 246 ns |
| `tb_button_conditioner` | 436 ns |
| `tb_sequence_detector` | 466 ns |
| `tb_traffic_light_controller` | 326 ns |
| `tb_fifo_sync` | 296 ns |
| `tb_uart_tx` | 586 ns |
| `tb_uart_rx` | 2807 ns |
| `tb_uart_loopback` | 258570 ns |

Ces durées correspondent au temps simulé, pas au temps d’exécution sur l’ordinateur.

Pour visualiser une trace :

```bash
gtkwave uart_loopback.vcd
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

Le nombre de comparaisons et le nombre d’octets transmis sont des indicateurs distincts. Ils ne constituent pas une mesure de couverture de code ou de couverture fonctionnelle.

Extensions prévues :

- Plusieurs paramètres et cas limites des composants génériques.
- FIFO de profondeur 1 et de profondeur non puissance de deux.
- Reset du RX pendant une réception.
- Trames UART consécutives, autres phases et écarts de baudrate.
- Modèles de référence et vérification structurée.

Les simulations RTL ne reproduisent pas la métastabilité physique, les délais d’implémentation ou les conditions électriques d’une carte.

Le bouclage complète les tests indépendants des modules ; il ne les remplace pas.

## Fichiers générés

Les fichiers de travail GHDL et les traces sont générés localement et exclus du dépôt par `.gitignore`, notamment :

```gitignore
*.cf
*.vcd
*.o
```

Le dépôt conserve les sources, les testbenches, les scripts et la documentation nécessaires pour reproduire les simulations.

## Prochaines étapes

- Vérification structurée avec VUnit ou cocotb
- ALU paramétrable
- Extension des tests aux cas limites et à plusieurs paramètres
- Intégration FIFO et UART
- Système pilotable par commandes UART
- Synthèse, contraintes et analyse de timing
- Génération du bitstream et validation sur carte FPGA