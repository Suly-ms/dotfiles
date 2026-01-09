#!/bin/bash
# --- A MODIFIER ---
GITHUB_USER="votre_pseudo_github_ici"
GITHUB_REPO="dotfiles"
# ------------------

GREEN='\033[0;32m'
NC='\033[0m' 

echo -e "${GREEN}### Démarrage de l'installation... ###${NC}"

# 1. INSTALLATION DES DÉPENDANCES SYSTÈME (AVANT ZSH)
echo -e "${GREEN}[+] Installation des pré-requis système (Zsh, Git, Zoxide, Bat)...${NC}"
sudo apt update
# On installe zoxide et bat ici pour éviter les erreurs "not found" plus tard
sudo apt install -y git zsh curl zoxide bat fzf dselect

if [ ! -f /usr/local/bin/bat ] && [ -f /usr/bin/batcat ]; then
    echo "Création du lien symbolique bat -> batcat..."
    sudo ln -s /usr/bin/batcat /usr/local/bin/bat
fi

echo -e "${GREEN}[+] Installation de la police MesloLGS NF (Nerd Font)...${NC}"
mkdir -p $HOME/.local/share/fonts
# On vérifie si la police est déjà là pour ne pas la télécharger 10 fois
if [ ! -f "$HOME/.local/share/fonts/MesloLGS NF Regular.ttf" ]; then
    cd $HOME/.local/share/fonts
    wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
    wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
    wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
    wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
    fc-cache -fv
    cd -
fi

# 2. INSTALLATION DE OH MY ZSH
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}[+] Installation de Oh My Zsh...${NC}"
    # On l'installe sans lancer zsh tout de suite (--unattended)
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 3. Clonage Git Bare
echo -e "${GREEN}[+] Récupération des dotfiles...${NC}"
if [ ! -d "$HOME/.cfg" ]; then
    git clone --bare "https://github.com/$GITHUB_USER/$GITHUB_REPO.git" $HOME/.cfg
fi

function config {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME "$@"
}

# 4. GESTION DES CONFLITS (Version Corrigée)
echo -e "${GREEN}[+] Résolution des conflits et Backup...${NC}"
mkdir -p $HOME/.config-backup

# Regex corrigée : attrape les fichiers cachés ET non-cachés (comme install.sh)
conflicting_files=$(config checkout 2>&1 | egrep "^\s+" | awk {'print $1'})

for file in $conflicting_files; do
    echo "Backup de : $file"
    mkdir -p "$HOME/.config-backup/$(dirname "$file")"
    mv "$HOME/$file" "$HOME/.config-backup/$file"
done

# Application de la config
echo -e "${GREEN}[+] Application de la configuration...${NC}"
config checkout
config config --local status.showUntrackedFiles no

# 5. INSTALLATION DES LOGICIELS (Mode "Liste Curée")
if [ -f "$HOME/mes_logiciels.txt" ]; then
    echo -e "${GREEN}[+] Installation de vos logiciels favoris...${NC}"
    
    # On lit le fichier, on ignore les commentaires (#) et les lignes vides
    # On remplace les retours à la ligne par des espaces pour faire une seule commande apt
    APPS=$(grep -vE "^\s*#" $HOME/mes_logiciels.txt | tr "\n" " ")
    
    if [ ! -z "$APPS" ]; then
        sudo apt install -y $APPS
    else
        echo "La liste de logiciels est vide."
    fi
else
    echo "Pas de fichier mes_logiciels.txt trouvé."
fi

# 6. Finalisation Zsh et Plugins
echo -e "${GREEN}[+] Configuration avancée de Zsh...${NC}"

# Changer le shell
sudo chsh -s $(which zsh) $USER

# Installation de l'outil Zoxide (nécessaire pour le plugin zsh)
sudo apt install -y zoxide

# Définition du dossier custom
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# A. Thème Powerlevel10k
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo "Installation du thème Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
fi

# B. Plugins
echo "Installation des plugins Zsh..."

# Autosuggestions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

# Syntax Highlighting
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# You Should Use
[ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ] && git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $ZSH_CUSTOM/plugins/you-should-use

# Zsh Bat
[ ! -d "$ZSH_CUSTOM/plugins/zsh-bat" ] && git clone https://github.com/fdellwing/zsh-bat.git $ZSH_CUSTOM/plugins/zsh-bat

# 8. RECHARGEMENT DE L'INTERFACE XFCE
echo -e "${GREEN}[+] Rechargement de la configuration des barres...${NC}"

# On tue le processus qui garde la config en mémoire pour qu'il relise les fichiers
xfce4-panel -r &>/dev/null & disown

# Si vous avez aussi des soucis avec le fond d'écran qui ne s'applique pas tout de suite :
xfdesktop --reload &>/dev/null & disown

echo -e "${GREEN}### TERMINÉ ! ###${NC}"
