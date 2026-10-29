# FPGA RTL to Bitstream

[![VHDL Simulation](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml/badge.svg?branch=main)](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml)

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt rassemble les sources RTL, les testbenches auto-vérifiants et une régression Python exécutée localement et automatiquement avec GitHub Actions.

## État actuel

Cinq modules RTL sont implémentés et vérifiés en simulation.

| Module | Description | Configuration testée | Vérifications |
|---|---|---|---:|
| `mux21` | Multiplexeur combinatoire 2 vers 1 | Entrées binaires | 8 |
| `adder_sub` | Additionneur/soustracteur non signé | `N = 8` | 4 |
| `reg_en` | Registre avec reset synchrone et enable | `WIDTH = 8` | 7 |
| `counter_en` | Compteur avec reset synchrone et enable | `WIDTH = 3` | 14 |
| `clock_enable` | Générateur d’autorisation périodique | `DIVISOR = 4` | 16 |
| **Total** | **5 testbenches** | | **49** |

La régression locale et la première exécution GitHub Actions ont réussi.

La synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte restent à réaliser.

## Prérequis

- Python 3
- GHDL avec prise en charge de VHDL-2008
- GTKWave, facultatif, pour visualiser les chronogrammes

Le script de régression utilise uniquement la bibliothèque standard Python.

Environnement de développement : Ubuntu 24.04 LTS, VS Code avec TerosHDL, Git et GitHub.

Pour consulter les versions installées :

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
├── rtl/
│   ├── mux21.vhd
│   ├── adder_sub.vhd
│   ├── reg_en.vhd
│   ├── counter_en.vhd
│   └── clock_enable.vhd
├── tb/
│   ├── tb_mux21.vhd
│   ├── tb_adder_sub.vhd
│   ├── tb_reg_en.vhd
│   ├── tb_counter_en.vhd
│   └── tb_clock_enable.vhd
└── scripts/
    └── run_tests.py
```

- `rtl/` : descriptions matérielles destinées à la synthèse.
- `tb/` : bancs de test de simulation.
- `scripts/` : automatisation de la régression.
- `.github/workflows/` : configuration de l’intégration continue.

Les dossiers de contraintes et de documentation seront complétés au fil du développement.

## Lancer tous les tests

Depuis la racine du dépôt :

```bash
python3 scripts/run_tests.py
```

Pour chaque module, le script analyse les sources, élabore le testbench et lance la simulation avec `--assert-level=error`.

Il s’arrête dès qu’une commande échoue et transmet son code de retour.

Résultat attendu après réussite des cinq testbenches :

```text
All 5 testbenches passed.
```

Pour consulter le code de retour immédiatement après l’exécution :

```bash
echo $?
```

- `0` : régression réussie.
- Autre valeur : échec.

Le script doit être exécuté depuis la racine du dépôt. Il ne génère pas de traces VCD.

## Intégration continue

Le workflow **VHDL Simulation**, défini dans `.github/workflows/simulation.yml`, s’exécute :

- À chaque push.
- Lors des événements de pull request pris en charge par le déclencheur.
- À la demande avec le bouton **Run workflow**.

Il utilise une machine GitHub sous Ubuntu 24.04 et réalise les étapes suivantes :

1. Récupération du dépôt.
2. Installation de GHDL et Python 3.
3. Affichage des versions des outils.
4. Exécution de `python3 scripts/run_tests.py`.

Le workflow possède un accès en lecture au contenu du dépôt et une limite d’exécution de 10 minutes.

Une erreur de compilation, d’élaboration ou de simulation fait échouer le travail. Les résultats et les journaux sont disponibles dans l’onglet [Actions](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml).

La CI exécute les tests RTL ; elle ne réalise pas encore la synthèse ou la validation matérielle.

## Modules RTL

### Multiplexeur — `mux21`

Circuit combinatoire sélectionnant une entrée selon `sel` :

| `sel` | Sortie |
|---|---|
| `'0'` | `y = a` |
| `'1'` | `y = b` |

Le testbench vérifie les huit combinaisons binaires de `a`, `b` et `sel`.

La détection d’erreur a été contrôlée en modifiant temporairement un résultat attendu : une assertion a interrompu la simulation. La valeur correcte a ensuite été rétablie.

### Additionneur/soustracteur — `adder_sub`

Le module effectue une opération sur deux entrées de `N` bits :

| `sub` | Opération |
|---|---|
| `'0'` | `sum = a + b` |
| `'1'` | `sum = a - b` |

Le générique `N` vaut 8 par défaut.

Les calculs utilisent `unsigned` et le paquet IEEE `numeric_std`. Le résultat est limité à `N` bits : les opérations sont réalisées modulo `2^N`, sans sortie de retenue ni indicateur de dépassement.

Quatre cas sont vérifiés sur 8 bits :

| Opération | Résultat |
|---|---:|
| `15 + 10` | 25 |
| `25 - 10` | 15 |
| `5 - 10` | 251 |
| `200 + 100` | 44 |

### Registre synchrone — `reg_en`

Le registre mémorise une donnée de `WIDTH` bits au front montant de l’horloge. La largeur par défaut est de 8 bits.

| Condition au front montant | Action |
|---|---|
| `rst = '1'` | Remettre `q` à zéro |
| `rst = '0'`, `en = '1'` | Charger `d` dans `q` |
| `rst = '0'`, `en = '0'` | Conserver la valeur |

Le reset est synchrone, actif à l’état haut et prioritaire sur l’enable.

Les sept vérifications portent sur le reset initial, deux chargements, le maintien entre les fronts, le maintien avec enable inactif, le caractère synchrone du reset et sa priorité.

### Compteur synchrone — `counter_en`

Le compteur mémorise une valeur non signée sur `WIDTH` bits. La largeur par défaut est de 8 bits.

| Condition au front montant | Action |
|---|---|
| `rst = '1'` | Remettre le compteur à zéro |
| `rst = '0'`, `en = '1'` | Incrémenter le compteur |
| `rst = '0'`, `en = '0'` | Conserver la valeur |

Le reset est synchrone, actif à l’état haut et prioritaire sur l’enable.

Le comptage s’effectue modulo `2^WIDTH`. Une incrémentation après la valeur maximale ramène le compteur à zéro.

Les 14 vérifications couvrent le reset initial, l’incrémentation, le maintien pendant deux cycles, le comptage jusqu’à 7, le débordement, la reprise du comptage et le comportement du reset.

Le chronogramme a également été inspecté pour confirmer le maintien, le débordement et le reset synchrone.

### Générateur de clock enable — `clock_enable`

Le module produit une autorisation `tick` pendant un cycle, tous les `DIVISOR` cycles d’horloge.

Le générique `DIVISOR` est strictement positif et vaut 4 par défaut. Le compteur interne évolue de `0` à `DIVISOR - 1`.

| Condition au front montant | Compteur suivant | `tick` suivant |
|---|---|---|
| `rst = '1'` | 0 | `'0'` |
| Hors reset, compteur au seuil | 0 | `'1'` |
| Hors reset, compteur sous le seuil | Compteur + 1 | `'0'` |

Le reset est synchrone et actif à l’état haut. Après sa désactivation, la première impulsion apparaît au `DIVISOR`-ième front montant.

`tick` est destiné à être utilisé comme enable dans une logique cadencée par `clk`, et non comme une nouvelle horloge.

Pour `DIVISOR = 4` :

```text
Cycle :  1 2 3 4 5 6 7 8
tick  :  0 0 0 1 0 0 0 1
```

Pour `DIVISOR = 1`, `tick` reste actif à chaque cycle hors reset.

Les 16 vérifications portent sur le reset initial, la périodicité des impulsions et le redémarrage d’une période complète après un reset intermédiaire.

## Simulations individuelles

Exécuter les commandes depuis la racine du dépôt.

### Multiplexeur

```bash
ghdl -a --std=08 rtl/mux21.vhd tb/tb_mux21.vhd
ghdl -e --std=08 tb_mux21
ghdl -r --std=08 tb_mux21 --assert-level=error --vcd=mux21.vcd
```

Résultat attendu : `MUX: all 8 binary cases passed.`

Fin de simulation : `80 ns`.

### Additionneur/soustracteur

```bash
ghdl -a --std=08 rtl/adder_sub.vhd tb/tb_adder_sub.vhd
ghdl -e --std=08 tb_adder_sub
ghdl -r --std=08 tb_adder_sub --assert-level=error --vcd=adder_sub.vcd
```

Résultat attendu : `All tests passed.`

Dernière vérification : `40 ns`.

### Registre synchrone

```bash
ghdl -a --std=08 rtl/reg_en.vhd tb/tb_reg_en.vhd
ghdl -e --std=08 tb_reg_en
ghdl -r --std=08 tb_reg_en --assert-level=error --vcd=reg_en.vcd
```

Résultat attendu : `REG_EN: all 7 checks passed.`

Fin de simulation : `46 ns`.

### Compteur synchrone

```bash
ghdl -a --std=08 rtl/counter_en.vhd tb/tb_counter_en.vhd
ghdl -e --std=08 tb_counter_en
ghdl -r --std=08 tb_counter_en --assert-level=error --vcd=counter_en.vcd
```

Résultat attendu : `COUNTER_EN: all 14 checks passed.`

Fin de simulation : `126 ns`.

### Générateur de clock enable

```bash
ghdl -a --std=08 rtl/clock_enable.vhd tb/tb_clock_enable.vhd
ghdl -e --std=08 tb_clock_enable
ghdl -r --std=08 tb_clock_enable --assert-level=error --vcd=clock_enable.vcd
```

Résultat attendu : `CLOCK_ENABLE: all 16 checks passed.`

Fin de simulation : `156 ns`.

### Visualiser les chronogrammes

Après génération des fichiers VCD :

```bash
gtkwave mux21.vcd
gtkwave adder_sub.vcd
gtkwave reg_en.vcd
gtkwave counter_en.vcd
gtkwave clock_enable.vcd
```

Les assertions comparent automatiquement les sorties aux valeurs attendues. Les chronogrammes permettent d’examiner les transitions des signaux.

## Périmètre et limites de vérification

| Module | Configuration testée | Limites principales |
|---|---|---|
| `mux21` | Huit combinaisons binaires | Valeurs non binaires non testées |
| `adder_sub` | `N = 8` | Opérandes non exhaustifs ; autres largeurs non testées |
| `reg_en` | `WIDTH = 8` | Autres largeurs non testées |
| `counter_en` | `WIDTH = 3` | Autres largeurs non testées |
| `clock_enable` | `DIVISOR = 4` | Autres diviseurs, notamment 1, non testés |

Les 49 vérifications ne constituent pas une mesure de couverture de code ou de couverture fonctionnelle. Une régression réussie confirme les scénarios exécutés, sans prouver tous les comportements possibles des modules.

L’arrêt au premier échec du script Python a été contrôlé par injection temporaire d’un résultat attendu incorrect dans le testbench du multiplexeur.

## Fichiers générés

Les fichiers de travail GHDL et les traces de simulation sont produits localement et exclus du dépôt par `.gitignore`, notamment :

```gitignore
*.cf
*.vcd
*.o
```

Le dépôt conserve les sources RTL, les testbenches, les scripts et la documentation nécessaires pour reproduire les simulations.

## Prochaines étapes

- Étendre les tests du générateur de clock enable aux cas limites
- Détecteur de front et anti-rebond
- Machines à états
- FIFO synchrone et UART
- Vérification structurée avec VUnit ou cocotb
- Intégration d’un système pilotable par UART
- Synthèse, contraintes et analyse de timing
- Génération du bitstream et validation sur carte FPGA