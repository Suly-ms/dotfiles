#!/bin/bash
# --- A MODIFIER ---
GITHUB_USER="Suly-ms"
GITHUB_REPO="dotfiles"
# ------------------

GREEN='\033[0;32m'
NC='\033[0m' 

echo -e "${GREEN}### Installation de votre environnement Debian + XFCE + Zsh ###${NC}"

# 1. Installation des bases
echo -e "${GREEN}[+] Maj système et installation Git/Zsh/Curl...${NC}"
sudo apt update && sudo apt install -y git zsh curl dselect

# 2. Installation Oh My Zsh (Auto)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}[+] Installation de Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 3. Clonage de la config (Git Bare)
echo -e "${GREEN}[+] Récupération des dotfiles...${NC}"
if [ ! -d "$HOME/.cfg" ]; then
    git clone --bare "https://github.com/$GITHUB_USER/$GITHUB_REPO.git" $HOME/.cfg
fi

function config {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME "$@"
}

# 4. Gestion des conflits (Correction du bug "Aucun fichier ou dossier de ce nom")
echo -e "${GREEN}[+] Résolution des conflits et Backup...${NC}"
mkdir -p $HOME/.config-backup

# On demande à Git quels fichiers posent problème
conflicting_files=$(config checkout 2>&1 | egrep "^\s+" | awk {'print $1'})

for file in $conflicting_files; do
    echo "Backup de : $file"
    # 1. On crée le dossier parent dans le backup
    mkdir -p "$HOME/.config-backup/$(dirname "$file")"
    # 2. On déplace le fichier
    mv "$HOME/$file" "$HOME/.config-backup/$file"
done

# 4b. Deuxième tentative d'application de la config
echo -e "${GREEN}[+] Application de la configuration...${NC}"
config checkout
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK] Config appliquée.${NC}"
else
    echo -e "${RED}[ERREUR] Impossible d'appliquer la config.${NC}"
    exit 1
fi
config config --local status.showUntrackedFiles no

# 5. Application de VOTRE config
config checkout
config config --local status.showUntrackedFiles no

# 6. Restauration des logiciels
if [ -f "$HOME/packages_list.txt" ]; then
    echo -e "${GREEN}[+] Réinstallation des logiciels...${NC}"
    sudo dpkg --set-selections < $HOME/packages_list.txt
    sudo apt-get dselect-upgrade -y
fi

# 7. Config Zsh par défaut
sudo chsh -s $(which zsh) $USER

# 8. Plugins Zsh (Optionnel mais recommandé)
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting

echo -e "${GREEN}### TERMINÉ ! ###${NC}"
echo "Veuillez redémarrer la session pour que XFCE charge le nouveau style."
