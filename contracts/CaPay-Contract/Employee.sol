// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./Company.sol";

contract Employee is Company {
    // Liste des opérateurs disponibles
    string[] operatorTypes = ["AIRTEL_MONEY", "MOOV"];

    // Struct représentant un employé
    struct EmployeeInfo {
        address employeeAddress;
        uint salaryAmount;  // Le salaire est directement exprimé en Wei
        string phoneNumber;
        string operatorType;  // Utilisation d'une chaîne de caractères pour l'opérateur
        bool isPaymentConfirmed;
    }

    // Mapping pour stocker les employés
    mapping(address => EmployeeInfo)  employees;
    address[]  employeeAddresses;

    // Mapping pour vérifier si une adresse est un employé
    mapping(address => bool)  isEmployee;
    mapping(string => bool)  phoneNumberExists;

    // Événements pour notifier les ajouts et suppressions d'employés
    event EmployeeAdded(address indexed employeeAddress, uint salaryAmount);
    event EmployeeRemoved(address indexed employeeAddress);
    event PaymentReceived(address indexed employeeAddress, uint amount);
    event PaymentConfirmed(address indexed employeeAddress, uint transactionId);

    // Fonction permettant d'ajouter un employé à une entreprise avec un salaire
    function addEmployee(address _companyAddress, address _employeeAddress, uint _salaryAmount, string memory _phoneNumber, 
    string memory _operator) public virtual onlyAdmin(_companyAddress) {
        // Vérifier que l'entreprise existe
        require(companies[_companyAddress].existsCompany, "L'entreprise n'existe pas.");
        // Vérifie si l'employé existe déjà dans l'entreprise
        require(!isEmployee[_employeeAddress], "Employe existe deja."); 
        // Vérifie si le numéro de téléphone est déjà associé à un autre employé
        require(!phoneNumberExists[_phoneNumber], "Numero de telephone deja associe a un employe."); 
        // Validation de l'opérateur
        bool validOperator = false;
        for (uint i = 0; i < operatorTypes.length; i++) {
            if (keccak256(abi.encodePacked(_operator)) == keccak256(abi.encodePacked(operatorTypes[i]))) {
                validOperator = true;
                break;
            }
        }
        require(validOperator, "Operateur non valide.");
        // Création d'un nouvel employé avec les informations fournies
        employees[_employeeAddress] = EmployeeInfo({
            employeeAddress: _employeeAddress, salaryAmount: _salaryAmount, phoneNumber: _phoneNumber, operatorType: _operator, 
            isPaymentConfirmed: false
        });
        // Ajout de l'adresse de l'employé
        employeeAddresses.push(_employeeAddress);
        // Marquage de l'adresse de l'employé comme existante
        isEmployee[_employeeAddress] = true;
        phoneNumberExists[_phoneNumber] = true;
        emit EmployeeAdded(_employeeAddress, _salaryAmount);
    }

    // Fonction pour ajuster les salaires
    function adjustSalary(address _companyAddress, address _employeeAddress, uint _newSalaryAmount) public virtual onlyAdmin(_companyAddress) {
        
        // Vérifier que l'entreprise existe
        require(companies[_companyAddress].existsCompany, "L'entreprise n'existe pas.");

        require(isEmployee[_employeeAddress], "Employe n'existe pas.");

        // Mettre à jour le salaire
        employees[_employeeAddress].salaryAmount = _newSalaryAmount;
    }

    // Fonction pour obtenir tous les employés d'une entreprise
    function getAllEmployees(address _companyAddress) public view virtual onlyAdmin(_companyAddress) returns (EmployeeInfo[] memory) {
        
        // Vérifier que l'entreprise existe
        require(companies[_companyAddress].existsCompany, "L'entreprise n'existe pas.");

        // S'assurer que l'entreprise a des employés
        require(employeeAddresses.length > 0, "Aucun employe trouve.");

        EmployeeInfo[] memory employeeList = new EmployeeInfo[](employeeAddresses.length);

        for (uint i = 0; i < employeeAddresses.length; i++) {
            address employeeAddr = employeeAddresses[i];
            employeeList[i] = employees[employeeAddr]; // Récupération des informations de l'employé
        }

        return employeeList; // Retourne la liste des employés
    }


}
