// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Company {
    // Structure représentant une entreprise
    struct CompanyInfo {
        string companyName;
        bool existsCompany;
        uint paymentDate;  // Date de paiement spécifiée pour l'entreprise
    }

    // Liste des adresses des entreprises
    address[] internal  companyAddresses;
    // Mapping pour stocker les informations des entreprises
    mapping(address => CompanyInfo) companies;

    // Événements pour notifier les créations d'entreprises et autres actions
    event CompanyCreated(address indexed companyAddress, string companyName, uint paymentDate);
    event FundsSupplied(address indexed companyAddress, uint amount);
    event PaymentDateUpdated(address indexed companyAddress, uint newPaymentDate);

    // Modificateur pour restreindre l'accès à l'administrateur (qui est l'adresse de la compagnie)
    modifier onlyAdmin(address _companyAddress) {
        require(msg.sender == _companyAddress, "Acces reserve a l'administrateur.");
        _;
    }

    // Fonction pour vérifier si une date est un dimanche
    function isSunday(uint timestamp) internal pure returns (bool) {
        // Le jour de la semaine est donné par le modulo 7 de la différence entre le timestamp et le 1er janvier 1970 (un jeudi).
        // Le jour de la semaine : 0 = jeudi, 1 = vendredi, ..., 6 = mercredi.
        // Donc si (timestamp + 4) % 7 == 0, c'est un dimanche.
        return (timestamp / 86400 + 4) % 7 == 0;
    }

    // Fonction pour obtenir le timestamp du 1er jour du mois
    function getFirstDayOfMonth(uint month, uint year) internal pure returns (uint) {
        uint[12] memory daysInMonth = [uint(31), 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if (isLeapYear(year)) {
            daysInMonth[1] = 29;  // Ajuster pour une année bissextile
        }

        uint secondsInDay = 86400;
        uint totalSeconds = 0;

        // Calculer le timestamp pour l'année en cours
        for (uint i = 1970; i < year; i++) {
            if (isLeapYear(i)) {
                totalSeconds += 31622400;  // Secondes dans une année bissextile
            } else {
                totalSeconds += 31536000;  // Secondes dans une année normale
            }
        }

        // Calculer le timestamp pour les mois précédents dans l'année
        for (uint i = 1; i < month; i++) {
            totalSeconds += daysInMonth[i - 1] * secondsInDay;
        }

        return totalSeconds;
    }

    // Fonction pour calculer la date de paiement en fonction des règles
    function calculatePaymentDate(uint month, uint year) internal  pure returns (uint) {
        uint firstDayTimestamp = getFirstDayOfMonth(month, year);

        // Si le 1er est un dimanche, ajouter un jour (86400 secondes)
        if (isSunday(firstDayTimestamp)) {
            return firstDayTimestamp + 86400;  // Le 2e jour du mois
        } else {
            return firstDayTimestamp;  // Le 1er jour du mois
        }
    }

    // Fonction pour créer une nouvelle entreprise avec une date de paiement automatique
    function createCompany(address _companyAddress,string memory _companyName,uint month, uint year ) public {
        
        require(!companies[_companyAddress].existsCompany, "L'entreprise existe deja.");

        uint paymentDate = calculatePaymentDate(month, year);

        // Enregistrer les informations de la nouvelle entreprise
        companies[_companyAddress] = CompanyInfo({
            companyName: _companyName,
            existsCompany: true,
            paymentDate: paymentDate
        });
        companyAddresses.push(_companyAddress);

        emit CompanyCreated(_companyAddress, _companyName, paymentDate);
    }

    // Fonction pour vérifier si une année est bissextile
    function isLeapYear(uint year) internal  pure returns (bool) {
        if (year % 4 == 0) {
            if (year % 100 == 0) {
                if (year % 400 == 0) {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        } else {
            return false;
        }
    }

    // Fonction pour vérifier si une entreprise existe
    function checkCompanyExists(address _companyAddress) internal  view returns (bool) {
        return companies[_companyAddress].existsCompany;
    }

    // Fonction pour obtenir le solde de l'entreprise(solde du contrat)
    function getContractBalance(address _companyAddress) public onlyAdmin(_companyAddress) view returns (uint) {
        require(companies[_companyAddress].existsCompany, "L'entreprise n'existe pas.");
        return address(this).balance;
    }

    // Fonction pour valider les fonds disponibles pour une entreprise
    function validateFunds(address _companyAddress, uint _requiredAmount) internal  view returns (bool) {
        require(companies[_companyAddress].existsCompany, "L'entreprise n'existe pas.");
        return address(this).balance >= _requiredAmount;
    }
}
