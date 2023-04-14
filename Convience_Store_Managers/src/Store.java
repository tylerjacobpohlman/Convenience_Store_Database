package murach.ap;

public class Store {
    private String storeNumber;
    private String address;
    private String city;
    private String state;
    private String zip;
    private String phoneNumber;

    public Store(String storeNumber, String address, String city, String state, String zip, String phoneNumber) {
        this.storeNumber = storeNumber;
        this.address = address;
        this.city = city;
        this.state = state;
        this.zip = zip;
        this.phoneNumber = phoneNumber;
    }

    public Store(String storeNumber, String state) {
        this.storeNumber = storeNumber;
        this.state = state;
        address = null;
        city = null;
        zip = null;
    }

    public String getStoreNumber() {
        return storeNumber;
    }
    public String getAddress() {
        return address;
    }
    public String getCity() {
        return city;
    }
    public String getState() {
        return state;
    }
    public String getZip() {
        return zip;
    }
    public String getPhoneNumber() {
        return phoneNumber;
    }
    
}
