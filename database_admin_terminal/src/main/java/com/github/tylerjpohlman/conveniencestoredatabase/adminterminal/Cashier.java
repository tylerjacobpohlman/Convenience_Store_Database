package com.github.tylerjpohlman.conveniencestoredatabase.adminterminal;

public class Cashier implements SQLScripts{
    String storeNumber;
    String cashierNumber;
    String firstName;
    String lastName;

    public Cashier(String storeNumber, String cashierNumber, String firstName, String lastName) {
        this.storeNumber = storeNumber;
        this.cashierNumber = cashierNumber;
        this.firstName = firstName;
        this.lastName = lastName;
    }

    @Override
    public String getInsertIntoDatabaseStatement() {
        return "CALL addCashier('" + storeNumber + "', '" + cashierNumber + "', '" + firstName + "', '"
                + lastName + "')";
    }
}
