package com.example.register_terminal;

public class Member {
    private String accountNumber;
    private String firstName;
    private String lastName;

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


    @Override
    public String toString() {
        return firstName + ' ' + lastName + '\n' +
                "Account Number: " + "*****" + accountNumber.substring(accountNumber.length() - 4 );

    }
}
