# FPGA RTL to Bitstream

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt rassemble les modules RTL, leurs testbenches auto-vérifiants et un script Python permettant de rejouer les simulations avec une seule commande.

## État actuel

Quatre modules RTL sont implémentés et vérifiés en simulation.

| Module | Description | Vérification |
|---|---|---|
| `mux21` | Multiplexeur combinatoire 2 vers 1, sur un bit | 8 combinaisons binaires |
| `adder_sub` | Additionneur/soustracteur combinatoire non signé, paramétrable en largeur | 4 cas dirigés sur 8 bits |
| `reg_en` | Registre paramétrable avec reset synchrone et enable | 7 vérifications sur 8 bits |
| `counter_en` | Compteur paramétrable avec reset synchrone et enable | 14 vérifications sur 3 bits |

La régression exécute **4 testbenches et 33 vérifications**. Elle s’arrête dès qu’une commande GHDL échoue.

La synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte restent à réaliser.

## Prérequis

- **Python 3** pour le script de régression
- **GHDL** avec prise en charge de VHDL-2008
- **GTKWave**, facultatif, pour examiner les chronogrammes

Environnement de développement : Ubuntu 24.04 LTS, VS Code avec TerosHDL, Git et GitHub.

Le script utilise uniquement la bibliothèque standard Python et ne nécessite aucun paquet Python supplémentaire.

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
│   └── counter_en.vhd
├── tb/
│   ├── tb_mux21.vhd
│   ├── tb_adder_sub.vhd
│   ├── tb_reg_en.vhd
│   └── tb_counter_en.vhd
└── scripts/
    └── run_tests.py
```

- `rtl/` : descriptions matérielles destinées à la synthèse.
- `tb/` : bancs de test utilisés pour la simulation.
- `scripts/` : automatisation des simulations.

Les dossiers de contraintes et de documentation seront complétés au fil du développement.

## Lancer tous les tests

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

Si les quatre testbenches réussissent, il affiche :

```text
All 4 testbenches passed.
```

Pour consulter le code de retour immédiatement après l’exécution :

```bash
echo $?
```

Un code `0` indique la réussite de la régression. Un code différent de zéro indique un échec.

La version actuelle du script doit être exécutée depuis la racine du dépôt. Elle ne génère pas de traces VCD ; les commandes individuelles ci-dessous permettent de les produire.

## Modules RTL

### Multiplexeur — `mux21`

Le multiplexeur sélectionne une entrée selon la valeur de `sel` :

| `sel` | Sortie |
|---|---|
| `'0'` | `y = a` |
| `'1'` | `y = b` |

Le circuit est combinatoire et ne possède ni horloge ni registre.

Le testbench applique les 8 combinaisons binaires de `a`, `b` et `sel`. Une assertion compare la sortie au résultat attendu pour chaque combinaison.

La détection d’erreur a été contrôlée en modifiant temporairement un résultat attendu. L’assertion a signalé l’écart et interrompu la simulation. Cette modification volontaire a ensuite été retirée.

Les tests couvrent les valeurs binaires `'0'` et `'1'`. Les autres valeurs de `std_logic`, notamment `'X'` et `'U'`, ne sont pas testées.

### Additionneur/soustracteur — `adder_sub`

Le module réalise une opération arithmétique sur deux entrées de `N` bits :

| `sub` | Opération |
|---|---|
| `'0'` | `sum = a + b` |
| `'1'` | `sum = a - b` |

La largeur est définie par le générique `N`, dont la valeur par défaut est 8.

Les calculs utilisent le type `unsigned` du paquet IEEE `numeric_std`. Le résultat reste limité à `N` bits : les opérations sont réalisées modulo `2^N`, sans sortie de retenue ni indicateur de dépassement.

Le testbench vérifie quatre cas pour `N = 8` :

| Opération | Résultat attendu |
|---|---|
| `15 + 10` | `25` |
| `25 - 10` | `15` |
| `5 - 10` | `251`, résultat modulo 256 |
| `200 + 100` | `44`, résultat modulo 256 |

Les quatre vérifications ont réussi. Les autres largeurs ne sont pas encore testées.

### Registre synchrone — `reg_en`

Le registre mémorise une donnée de `WIDTH` bits au front montant de l’horloge. La largeur par défaut est de 8 bits.

| Condition au front montant | Action |
|---|---|
| `rst = '1'` | Remettre `q` à zéro |
| `rst = '0'` et `en = '1'` | Charger `d` dans `q` |
| `rst = '0'` et `en = '0'` | Conserver la valeur précédente |

Le reset est synchrone, actif à l’état haut et prioritaire sur l’enable. Son activation entre deux fronts montants ne modifie pas immédiatement la sortie.

Le module ne définit pas de valeur initiale pour `q`. Le testbench applique un reset au début de la simulation.

Les sept vérifications portent sur :

1. La remise à zéro au front montant.
2. Le chargement de la valeur 12.
3. La conservation de la sortie lorsque l’entrée change entre les fronts montants.
4. Le chargement de la valeur 25.
5. La conservation de la valeur avec enable inactif.
6. L’absence de remise à zéro avant le front montant.
7. La priorité du reset sur l’enable.

Les sept vérifications ont réussi sur une instance de 8 bits. La simulation se termine à `46 ns`.

Les autres largeurs ne sont pas encore testées.

### Compteur synchrone — `counter_en`

Le compteur mémorise une valeur non signée sur `WIDTH` bits. La largeur par défaut est de 8 bits.

| Condition au front montant | Action |
|---|---|
| `rst = '1'` | Remettre le compteur à zéro |
| `rst = '0'` et `en = '1'` | Incrémenter le compteur |
| `rst = '0'` et `en = '0'` | Conserver la valeur précédente |

Le reset est synchrone, actif à l’état haut et prioritaire sur l’enable.

Le comptage s’effectue modulo `2^WIDTH`. Après la valeur maximale, une nouvelle incrémentation ramène le compteur à zéro. Avec l’enable inactif, la valeur maximale est conservée.

Le testbench réalise 14 vérifications sur une instance de 3 bits :

| Scénario | Nombre de vérifications |
|---|---:|
| Reset initial | 1 |
| Première incrémentation | 1 |
| Maintien pendant deux cycles | 2 |
| Comptage des valeurs 2 à 7 | 6 |
| Retour à zéro après 7 | 1 |
| Reprise du comptage après débordement | 1 |
| Absence d’action du reset avant le front montant | 1 |
| Priorité du reset sur l’enable | 1 |
| **Total** | **14** |

Les 14 vérifications ont réussi. La simulation se termine à `126 ns`.

Le chronogramme a également été inspecté : lors de l’activation du reset à `120 ns`, la sortie conserve sa valeur jusqu’au front montant à `125 ns`.

Les autres largeurs ne sont pas encore testées.

## Simulations individuelles et chronogrammes

Exécuter les commandes depuis la racine du dépôt.

L’option `--std=08` sélectionne VHDL-2008. Elle est utilisée pour l’analyse, l’élaboration et l’exécution.

### Multiplexeur

```bash
ghdl -a --std=08 rtl/mux21.vhd tb/tb_mux21.vhd
ghdl -e --std=08 tb_mux21
ghdl -r --std=08 tb_mux21 --assert-level=error --vcd=mux21.vcd
```

Message attendu :

```text
MUX: all 8 binary cases passed.
```

Fin de simulation : `80 ns`.

### Additionneur/soustracteur

```bash
ghdl -a --std=08 rtl/adder_sub.vhd tb/tb_adder_sub.vhd
ghdl -e --std=08 tb_adder_sub
ghdl -r --std=08 tb_adder_sub --assert-level=error --vcd=adder_sub.vcd
```

Message attendu :

```text
All tests passed.
```

Dernière vérification : `40 ns`.

### Registre synchrone

```bash
ghdl -a --std=08 rtl/reg_en.vhd tb/tb_reg_en.vhd
ghdl -e --std=08 tb_reg_en
ghdl -r --std=08 tb_reg_en --assert-level=error --vcd=reg_en.vcd
```

Message attendu :

```text
REG_EN: all 7 checks passed.
```

Fin de simulation : `46 ns`.

### Compteur synchrone

```bash
ghdl -a --std=08 rtl/counter_en.vhd tb/tb_counter_en.vhd
ghdl -e --std=08 tb_counter_en
ghdl -r --std=08 tb_counter_en --assert-level=error --vcd=counter_en.vcd
```

Message attendu :

```text
COUNTER_EN: all 14 checks passed.
```

Fin de simulation : `126 ns`.

### Visualisation

Après génération des fichiers VCD :

```bash
gtkwave mux21.vcd
gtkwave adder_sub.vcd
gtkwave reg_en.vcd
gtkwave counter_en.vcd
```

Les traces permettent d’examiner les transitions des signaux. Les assertions assurent la vérification automatique des résultats attendus.

Pour les circuits séquentiels, afficher l’horloge, le reset, l’enable et les données. Un affichage décimal non signé facilite la lecture des valeurs du compteur.

## Stratégie de vérification

Les testbenches utilisent des scénarios dirigés et des assertions.

L’option `--assert-level=error` interrompt une simulation lorsqu’une assertion de niveau `error` ou supérieur échoue. Le script Python interrompt ensuite la régression lorsqu’il reçoit un code de retour non nul.

Ce comportement a été contrôlé avec une erreur attendue volontairement incorrecte dans le testbench du multiplexeur :

- L’assertion a échoué.
- La régression s’est arrêtée avant les autres testbenches.
- Le message final de réussite n’a pas été affiché.
- Après restauration du test, les quatre testbenches ont réussi avec un code de retour global égal à `0`.

### Périmètre et limites

| Module | Périmètre actuel | Limites |
|---|---|---|
| `mux21` | Toutes les combinaisons des trois entrées binaires | Autres valeurs de `std_logic` non testées |
| `adder_sub` | Quatre cas dirigés sur 8 bits | Opérandes non couverts exhaustivement ; autres largeurs non testées |
| `reg_en` | Sept vérifications dirigées sur 8 bits | Autres largeurs non testées |
| `counter_en` | Quatorze vérifications sur 3 bits et inspection du chronogramme | Autres largeurs non testées |

Les 33 vérifications ne constituent pas une mesure de couverture de code ou de couverture fonctionnelle. Leur réussite concerne les scénarios exécutés, sans prouver tous les comportements possibles des modules.

## Fichiers générés

Les fichiers de travail GHDL et les traces de simulation sont produits localement et exclus du dépôt par `.gitignore`, notamment :

```gitignore
*.cf
*.vcd
*.o
```

Le dépôt conserve les sources RTL, les testbenches, les scripts et la documentation nécessaires pour reproduire les simulations.

## Prochaines étapes

- Générateur de clock enable
- Détecteur de front et anti-rebond
- Machines à états
- FIFO synchrone et UART
- Vérification structurée avec VUnit ou cocotb
- Intégration des modules dans un système pilotable par UART
- Régression automatique avec GitHub Actions
- Synthèse, contraintes et analyse de timing
- Génération du bitstream et validation sur carte FPGA

Les fonctionnalités sont ajoutées progressivement, avec leurs tests et leur documentation.