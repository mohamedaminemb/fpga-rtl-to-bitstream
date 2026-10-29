# FPGA RTL to Bitstream

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt rassemble les modules RTL, leurs testbenches auto-vérifiants et un script Python permettant de rejouer les simulations avec une seule commande.

## État actuel

Cinq modules RTL sont implémentés.

| Module | Description | Vérifications |
|---|---|---:|
| `mux21` | Multiplexeur combinatoire 2 vers 1, sur un bit | 8 |
| `adder_sub` | Additionneur/soustracteur combinatoire non signé | 4 |
| `reg_en` | Registre avec reset synchrone et enable | 7 |
| `counter_en` | Compteur avec reset synchrone et enable | 14 |
| `clock_enable` | Générateur d’autorisation périodique | 16 |
| **Total** | **5 testbenches** | **49** |

Les quatre premiers testbenches ont été validés ensemble par le script de régression. Le testbench de `clock_enable` a également réussi en simulation individuelle.

La synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte restent à réaliser.

## Prérequis

- **Python 3** pour le script de régression
- **GHDL** avec prise en charge de VHDL-2008
- **GTKWave**, facultatif, pour examiner les chronogrammes

Environnement de développement : Ubuntu 24.04 LTS, VS Code avec TerosHDL, Git et GitHub.

Le script utilise uniquement la bibliothèque standard Python.

Pour consulter les versions installées :

```bash
python3 --version
ghdl --version
gtkwave --version
```

## Organisation du dépôt

```text
fpga-rtl-to-bitstream/
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
- `tb/` : bancs de test utilisés pour la simulation.
- `scripts/` : automatisation des simulations.

Les dossiers de contraintes et de documentation seront complétés au fil du développement.

## Lancer la régression

Depuis la racine du dépôt :

```bash
python3 scripts/run_tests.py
```

Pour chaque module, le script :

1. Analyse le fichier RTL et son testbench.
2. Élabore le testbench.
3. Exécute la simulation avec `--assert-level=error`.
4. Affiche `PASS` si les commandes réussissent.

Le script s’arrête au premier échec et transmet le code de retour de la commande concernée.

Après réussite des cinq testbenches, le message attendu est :

```text
All 5 testbenches passed.
```

Pour consulter le code de retour immédiatement après l’exécution :

```bash
echo $?
```

Un code `0` indique la réussite. Un code différent de zéro indique un échec.

Le script doit être exécuté depuis la racine du dépôt. Il ne génère pas de fichiers VCD ; les simulations individuelles ci-dessous permettent de les produire.

## Modules RTL

### Multiplexeur — `mux21`

Le multiplexeur sélectionne une entrée selon `sel` :

| `sel` | Sortie |
|---|---|
| `'0'` | `y = a` |
| `'1'` | `y = b` |

Le circuit est combinatoire.

Le testbench vérifie les huit combinaisons binaires des entrées. La détection d’erreur a été contrôlée en modifiant temporairement un résultat attendu : une assertion a interrompu la simulation. Cette modification a ensuite été retirée.

Les autres valeurs de `std_logic`, notamment `'X'` et `'U'`, ne sont pas testées.

### Additionneur/soustracteur — `adder_sub`

Le module effectue une opération sur deux entrées de `N` bits :

| `sub` | Opération |
|---|---|
| `'0'` | `sum = a + b` |
| `'1'` | `sum = a - b` |

Le générique `N` vaut 8 par défaut.

Les calculs utilisent `unsigned` et le paquet IEEE `numeric_std`. Le résultat est limité à `N` bits : les opérations sont réalisées modulo `2^N`, sans sortie de retenue ni indicateur de dépassement.

Quatre cas sont vérifiés sur 8 bits :

| Opération | Résultat attendu |
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

Le testbench applique un reset initial puis vérifie les chargements, le maintien entre les fronts, le maintien avec enable inactif, le caractère synchrone du reset et sa priorité.

Les sept vérifications ont réussi sur une instance de 8 bits.

### Compteur synchrone — `counter_en`

Le compteur mémorise une valeur non signée sur `WIDTH` bits. La largeur par défaut est de 8 bits.

| Condition au front montant | Action |
|---|---|
| `rst = '1'` | Remettre le compteur à zéro |
| `rst = '0'`, `en = '1'` | Incrémenter le compteur |
| `rst = '0'`, `en = '0'` | Conserver la valeur |

Le reset est synchrone, actif à l’état haut et prioritaire sur l’enable.

Le comptage s’effectue modulo `2^WIDTH`. Une incrémentation après la valeur maximale ramène le compteur à zéro.

Les 14 vérifications portent sur le reset initial, l’incrémentation, le maintien pendant deux cycles, le comptage jusqu’à la valeur maximale, le débordement, la reprise du comptage et le comportement du reset.

Elles ont réussi sur une instance de 3 bits. Le chronogramme a également été inspecté.

### Générateur de clock enable — `clock_enable`

Le module produit une autorisation `tick` pendant un cycle, tous les `DIVISOR` cycles d’horloge. Le générique `DIVISOR` est strictement positif et vaut 4 par défaut.

Le compteur interne évolue de `0` à `DIVISOR - 1` :

| Condition au front montant | Compteur suivant | `tick` suivant |
|---|---|---|
| `rst = '1'` | 0 | `'0'` |
| Hors reset, compteur au seuil | 0 | `'1'` |
| Hors reset, compteur sous le seuil | Compteur + 1 | `'0'` |

Le reset est synchrone et actif à l’état haut. Après sa désactivation, la première impulsion apparaît au `DIVISOR`-ième front montant.

`tick` est destiné à être utilisé comme enable dans une logique cadencée par `clk`. Il ne constitue pas une nouvelle horloge.

Pour `DIVISOR = 4`, la séquence après reset est :

```text
Cycle :  1 2 3 4 5 6 7 8
tick  :  0 0 0 1 0 0 0 1
```

Pour `DIVISOR = 1`, `tick` reste actif à chaque cycle hors reset.

Le testbench réalise 16 vérifications avec `DIVISOR = 4` :

| Scénario | Vérifications |
|---|---:|
| Reset initial | 1 |
| Huit cycles hors reset | 8 |
| Deux cycles supplémentaires avant le reset | 2 |
| Reset au milieu d’une période | 1 |
| Quatre cycles après redémarrage | 4 |
| **Total** | **16** |

Les 16 vérifications ont réussi. Le cas limite `DIVISOR = 1` n’a pas encore été vérifié en simulation.

## Simulations individuelles

Exécuter les commandes depuis la racine du dépôt.

### Multiplexeur

```bash
ghdl -a --std=08 rtl/mux21.vhd tb/tb_mux21.vhd
ghdl -e --std=08 tb_mux21
ghdl -r --std=08 tb_mux21 --assert-level=error --vcd=mux21.vcd
```

Message attendu : `MUX: all 8 binary cases passed.`

Fin de simulation : `80 ns`.

### Additionneur/soustracteur

```bash
ghdl -a --std=08 rtl/adder_sub.vhd tb/tb_adder_sub.vhd
ghdl -e --std=08 tb_adder_sub
ghdl -r --std=08 tb_adder_sub --assert-level=error --vcd=adder_sub.vcd
```

Message attendu : `All tests passed.`

Dernière vérification : `40 ns`.

### Registre synchrone

```bash
ghdl -a --std=08 rtl/reg_en.vhd tb/tb_reg_en.vhd
ghdl -e --std=08 tb_reg_en
ghdl -r --std=08 tb_reg_en --assert-level=error --vcd=reg_en.vcd
```

Message attendu : `REG_EN: all 7 checks passed.`

Fin de simulation : `46 ns`.

### Compteur synchrone

```bash
ghdl -a --std=08 rtl/counter_en.vhd tb/tb_counter_en.vhd
ghdl -e --std=08 tb_counter_en
ghdl -r --std=08 tb_counter_en --assert-level=error --vcd=counter_en.vcd
```

Message attendu : `COUNTER_EN: all 14 checks passed.`

Fin de simulation : `126 ns`.

### Générateur de clock enable

```bash
ghdl -a --std=08 rtl/clock_enable.vhd tb/tb_clock_enable.vhd
ghdl -e --std=08 tb_clock_enable
ghdl -r --std=08 tb_clock_enable --assert-level=error --vcd=clock_enable.vcd
```

Message attendu : `CLOCK_ENABLE: all 16 checks passed.`

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

Les chronogrammes permettent d’examiner les transitions des signaux. Les assertions assurent la comparaison automatique avec les résultats attendus.

## Stratégie de vérification et limites

Les testbenches utilisent des scénarios dirigés et des assertions.

L’option `--assert-level=error` interrompt la simulation lorsqu’une assertion de niveau `error` ou supérieur échoue. Le script Python interrompt la régression lorsqu’une commande renvoie un code non nul.

L’arrêt au premier échec a été contrôlé par injection temporaire d’un résultat attendu incorrect dans le testbench du multiplexeur. Après restauration, la régression des quatre premiers modules a réussi avec un code de retour égal à `0`.

| Module | Configuration testée | Limites principales |
|---|---|---|
| `mux21` | Huit combinaisons binaires | Valeurs non binaires non testées |
| `adder_sub` | `N = 8` | Opérandes non exhaustifs ; autres largeurs non testées |
| `reg_en` | `WIDTH = 8` | Autres largeurs non testées |
| `counter_en` | `WIDTH = 3` | Autres largeurs non testées |
| `clock_enable` | `DIVISOR = 4` | Autres diviseurs non testés |

Les 49 vérifications ne constituent pas une mesure de couverture de code ou de couverture fonctionnelle. Leur réussite concerne les scénarios exécutés.

## Fichiers générés

Les fichiers de travail GHDL et les traces de simulation sont générés localement et exclus du dépôt par `.gitignore`, notamment :

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
- Régression automatique avec GitHub Actions
- Synthèse, contraintes et analyse de timing
- Génération du bitstream et validation sur carte FPGA