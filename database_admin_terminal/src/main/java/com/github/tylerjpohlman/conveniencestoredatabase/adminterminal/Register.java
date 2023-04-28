package com.github.tylerjpohlman.conveniencestoredatabase.adminterminal;

public class Register implements SQLScripts{
    String number;
    String type;
    String store;

    public Register(String number, String type, String store) {
        this.number = number;
        this.type = type;
        this.store = store;
    }

    public String getNumber() {
        return number;
    }
    public String getType() {
        return type;
    }
    public String getStore() {
        return store;
    }


    @Override
    public String getInsertIntoDatabaseStatement() {
        return "Call addRegister('" + store + "', '" + number + "', '" + type + "')";

    }
}
