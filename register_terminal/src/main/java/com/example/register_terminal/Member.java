package com.example.register_terminal;

public class Member implements SQLScripts{
    private String accountNumber;
    private String firstName;
    private String lastName;
    private String phoneNumber;
    private String email;
    private double totalSavings;

    public Member(String accountNumber, String firstName, String lastName, String phoneNumber, String email, double totalSavings) {
        this.accountNumber = accountNumber;
        this.firstName = firstName;
        this.lastName = lastName;
        this.phoneNumber = phoneNumber;
        this.email = email;
        this.totalSavings = totalSavings;
    }

    public Member(String accountNumber, String firstName, String lastName) {
        this.accountNumber = accountNumber;
        this.firstName = firstName;
        this.lastName = lastName;
    }

    public String getAccountNumber() {
        return accountNumber;
    }
    public String getFirstName() {
        return firstName;
    }
    public String getLastName() {
        return lastName;
    }
    public String getPhoneNumber() {
        return phoneNumber;
    }
    public String getEmail() {
        return email;
    }
    public double getTotalSavings() {
        return totalSavings;
    }


    @Override
    public String getInsertIntoDatabaseStatement() {
        return "CALL addMember('" + accountNumber + "', '" + firstName + "', '" + lastName + "', '"
                + phoneNumber + "', '" + email + "')";
    }

    @Override
    public String toString() {
        return firstName + ' ' + lastName + '\n' +
                "Account Number: " + "*****" + accountNumber.substring(accountNumber.length() - 4 );

    }
}
