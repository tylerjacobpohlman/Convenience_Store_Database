package murach.ap;

public class Member {
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

    public Member(String accountNumber, String firstName, String lastName, String phoneNumber, String email) {
        this.accountNumber = accountNumber;
        this.firstName = firstName;
        this.lastName = lastName;
        this.phoneNumber = phoneNumber;
        this.email = email;
        totalSavings = 0.0;
    }

    public Member(String accountNumber, String phoneNumber, String email) {
        this.accountNumber = accountNumber;
        this.phoneNumber = phoneNumber;
        this.email = email;
        firstName = null;
        lastName = null;
        totalSavings = 0.0;
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
    
    
}
