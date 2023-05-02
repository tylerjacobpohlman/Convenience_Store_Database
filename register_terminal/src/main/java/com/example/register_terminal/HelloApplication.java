package com.example.register_terminal;

import javafx.application.Application;
import javafx.event.ActionEvent;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;
import javafx.scene.control.TextField;
import javafx.scene.layout.AnchorPane;
import javafx.stage.Stage;

import java.io.IOException;
import java.sql.*;

public class HelloApplication extends Application {
    //Lambda expression shenanigans forced me to put the objects used for SQL outside the start method
    /*
     * SQL OBJECTS
     */
    //working in the hvs database
    String dbUrl = "jdbc:mysql://localhost:3306/hvs";
    //shouldn't use root, will change to proper credentials once created
    String username;
    String password;
    //will change to proper login with each cashier having an individual user account
    String cashierNum;
    String registerNum;
    Connection connection;
    PreparedStatement ps;
    ResultSet rs;
    //stored as null by default to indicate no membership is provided
    Member givenMember = null;

    @Override
    public void start(Stage stage) throws IOException {
        //INTRODUCTION SCENE
        AnchorPane introductionPane = new AnchorPane();
        Scene introductionScene = new Scene(introductionPane, 800, 600);

        //MAIN MENU PANE
        AnchorPane mainPane = new AnchorPane();
        Scene mainScene = new Scene(mainPane, 800, 600);

        //MEMBER ID PANE
        AnchorPane memberIDPane = new AnchorPane();
        Scene memberIDScene = new Scene(memberIDPane, 800, 600);

        /*
         * ITEMS USED FOR INTRODUCTION SCENE
         */
        Label introductionLabel = new Label("Welcome to the HVS register application!");
        AnchorPane.setLeftAnchor(introductionLabel, 40.0);
        AnchorPane.setTopAnchor(introductionLabel, 20.0);
        Label introductionSubLabel = new Label("Please Enter the proper login details below:");
        AnchorPane.setLeftAnchor(introductionSubLabel, 40.0);
        AnchorPane.setTopAnchor(introductionSubLabel, 60.0);
        Label usernameLabel = new Label("Username:");
        AnchorPane.setLeftAnchor(usernameLabel, 40.0);
        AnchorPane.setTopAnchor(usernameLabel, 100.0);

        //TextField usernameTextField = new TextField();
        TextField usernameTextField = new TextField("root");

        AnchorPane.setLeftAnchor(usernameTextField, 40.0);
        AnchorPane.setTopAnchor(usernameTextField, 120.0);
        Label passwordLabel = new Label("Password:");
        AnchorPane.setLeftAnchor(passwordLabel, 40.0);
        AnchorPane.setTopAnchor(passwordLabel, 160.0);

        //TextField passwordTextField = new TextField();
        TextField passwordTextField = new TextField("187421");

        AnchorPane.setLeftAnchor(passwordTextField, 40.0);
        AnchorPane.setTopAnchor(passwordTextField, 180.0);
        Label registerNumLabel = new Label("Register Number:");
        AnchorPane.setLeftAnchor(registerNumLabel, 40.0);
        AnchorPane.setTopAnchor(registerNumLabel, 220.0);

        //TextField registerNumTextField = new TextField();
        TextField registerNumTextField = new TextField("552");

        AnchorPane.setLeftAnchor(registerNumTextField, 40.0);
        AnchorPane.setTopAnchor(registerNumTextField, 240.0);
        Label employeeNumLabel = new Label("Employee ID:");
        AnchorPane.setLeftAnchor(employeeNumLabel, 40.0);
        AnchorPane.setTopAnchor(employeeNumLabel, 280.0);

        //TextField employeeNumTextField = new TextField();
        TextField employeeNumTextField = new TextField("324");

        AnchorPane.setLeftAnchor(employeeNumTextField, 40.0);
        AnchorPane.setTopAnchor(employeeNumTextField, 300.0);
        Button introductionEnterButton = new Button("ENTER");
        AnchorPane.setLeftAnchor(introductionEnterButton, 40.0);
        AnchorPane.setTopAnchor(introductionEnterButton, 340.0);
        Label introductionErrorLabel = new Label();
        AnchorPane.setRightAnchor(introductionErrorLabel, 150.0);
        AnchorPane.setBottomAnchor(introductionErrorLabel, 60.0);
        introductionPane.getChildren().addAll(introductionLabel, introductionSubLabel, usernameLabel, usernameTextField,
                passwordLabel, passwordTextField, registerNumLabel, registerNumTextField, employeeNumLabel,
                employeeNumTextField, introductionEnterButton, introductionErrorLabel);

        /*
         * ITEMS USED FOR MAIN SCENE
         */

        Label addressLabel = new Label();
        AnchorPane.setLeftAnchor(addressLabel, 40.0);
        AnchorPane.setTopAnchor(addressLabel, 20.0);
        ListView<Item> addedItems = new ListView<>();
        AnchorPane.setLeftAnchor(addedItems, 40.0);
        AnchorPane.setTopAnchor(addedItems, 60.0);
        Label addItemByUPCLabel = new Label("Item UPC:");
        AnchorPane.setLeftAnchor(addItemByUPCLabel, 40.0);
        AnchorPane.setBottomAnchor(addItemByUPCLabel, 100.0);
        TextField addItemByUPCTextField = new TextField();
        AnchorPane.setLeftAnchor(addItemByUPCTextField, 40.0);
        AnchorPane.setBottomAnchor(addItemByUPCTextField, 60.0);
        Button addItemByUPCButton = new Button("ADD ITEM");
        AnchorPane.setLeftAnchor(addItemByUPCButton, 40.0);
        AnchorPane.setBottomAnchor(addItemByUPCButton, 20.0);
        Button memeberLookupButton = new Button("Member Lookup");
        AnchorPane.setRightAnchor(memeberLookupButton, 40.0);
        AnchorPane.setTopAnchor(memeberLookupButton, 20.0);
        Button itemLookupButton = new Button("Item Lookup");
        AnchorPane.setRightAnchor(itemLookupButton, 40.0);
        AnchorPane.setTopAnchor(itemLookupButton, 60.0);
        Button finishAndPayButton = new Button("Finish and Pay");
        AnchorPane.setRightAnchor(finishAndPayButton, 40.0);
        AnchorPane.setBottomAnchor(finishAndPayButton, 100.0);
        Label mainMenuErrorLabel = new Label("");
        AnchorPane.setRightAnchor(mainMenuErrorLabel, 40.0);
        AnchorPane.setBottomAnchor(mainMenuErrorLabel, 60.0);
        Label mainMenuMemberStatus = new Label("");
        AnchorPane.setRightAnchor(mainMenuMemberStatus, 40.0);
        AnchorPane.setBottomAnchor(mainMenuMemberStatus, 300.0);
        mainPane.getChildren().addAll(addressLabel, addedItems, addItemByUPCLabel, addItemByUPCTextField,
                addItemByUPCButton, memeberLookupButton, itemLookupButton, finishAndPayButton,
                mainMenuErrorLabel, mainMenuMemberStatus);

        /*
         * ITEMS USED FOR MEMBER ID LOOKUP SCENE
         */
        Label memberIDLabel = new Label("Member ID Lookup\nEnter phone number/member ID number below");
        AnchorPane.setLeftAnchor(addressLabel, 40.0);
        AnchorPane.setTopAnchor(addressLabel, 20.0);
        Label phoneNumberLabel = new Label("Phone Number:");
        AnchorPane.setLeftAnchor(phoneNumberLabel, 40.0);
        AnchorPane.setTopAnchor(phoneNumberLabel, 100.0);
        TextField phoneNumberTextField = new TextField();
        AnchorPane.setLeftAnchor(phoneNumberTextField, 40.0);
        AnchorPane.setTopAnchor(phoneNumberTextField, 120.0);
        Label memberIDLookupLabel = new Label("Member ID");
        AnchorPane.setLeftAnchor(memberIDLookupLabel, 40.0);
        AnchorPane.setTopAnchor(memberIDLookupLabel, 160.0);
        TextField memberIDTextField = new TextField();
        AnchorPane.setLeftAnchor(memberIDTextField, 40.0);
        AnchorPane.setTopAnchor(memberIDTextField, 180.0);
        Button memberIDEnterButton = new Button("ENTER");
        AnchorPane.setLeftAnchor(memberIDEnterButton, 120.0);
        AnchorPane.setTopAnchor(memberIDEnterButton, 340.0);
        Button memberIDGoBackButton = new Button("GO BACK");
        AnchorPane.setLeftAnchor(memberIDGoBackButton, 40.0);
        AnchorPane.setTopAnchor(memberIDGoBackButton, 340.0);
        Label memberIDErrorLabel = new Label("");
        AnchorPane.setRightAnchor(memberIDErrorLabel, 40.0);
        AnchorPane.setBottomAnchor(memberIDErrorLabel, 60.0);
        memberIDPane.getChildren().addAll(memberIDLabel, phoneNumberLabel, phoneNumberTextField, memberIDLookupLabel,
                memberIDTextField, memberIDEnterButton, memberIDGoBackButton, memberIDErrorLabel);

        /*
         * INTRODUCTION SCENE
         */
        stage.setScene(introductionScene);
        //button click
        introductionEnterButton.setOnAction(ActionEvent -> {
            try {
                //resets the error label
                introductionErrorLabel.setText("");

                username = usernameTextField.getText();
                password = passwordTextField.getText();
                cashierNum = employeeNumTextField.getText();
                registerNum = registerNumTextField.getText();

                //when one or more of the text fields have no text
                if(username.equals("") || password.equals("") || cashierNum.equals("") || registerNum.equals("")) {
                    introductionErrorLabel.setText("Error: One or more of the text fields are empty!");
                }
                else {
                    //tries to establish a connection to the database
                    connection = DriverManager.getConnection(dbUrl, username, password);

                    //ties the login procedure from the database
                    String login = "CALL cashierRegisterLogin('" + cashierNum + "', '" + registerNum + "')";
                    ps = connection.prepareStatement(login);
                    ps.execute();

                    //grabs the address using the registerID
                    //NOTE: This is incredibly sloppy! I wasn't sure how to grab the result of a function, so I turned
                    // storeAddressLookupFromRegister into a procedure and grabbed the address this way
                    try {
                        String addressLookup = "Call storeAddressLookupFromRegister('" + registerNum + "')";
                        ps = connection.prepareStatement(addressLookup);
                        //stores the address in the result set
                        rs = ps.executeQuery();
                        while(rs.next() ) {
                            addressLabel.setText(rs.getString(1) );
                        }
                    } catch (SQLException e) {
                        addressLabel.setText("ERROR: Unable to find address\nPlease contact IT specialist");
                    }

                    //if all goes well, on to the next scene!
                    stage.setScene(mainScene);
                }
            //any error connecting to the database and/or executing the query
            } catch (SQLException e) {
                //introductionErrorLabel.setText("Error: Username and/or password is incorrect");
                introductionErrorLabel.setText("Error: Unable to establish connection...\n" +
                                               "Ensure the username, password, cashier  \n" +
                                               "ID, and register ID are correct");
            }

        });

        /*
         * MAIN SCENE
         */
        addItemByUPCButton.setOnAction(ActionEvent -> {
            //reset the error label
            mainMenuErrorLabel.setText("");

            //checks if there's any text at all
            if(addItemByUPCTextField.getText().isEmpty() ) {
                mainMenuErrorLabel.setText("Please type in the UPC number first");
            }
            else {


                //elements of the Item to grab
                String upc = addItemByUPCTextField.getText();
                String name = null;
                double price = 0;
                double discount = 0;

                try {
                    String itemUPCLookup = "Call itemUPCLookup('" + upc + "')";
                    ps = connection.prepareStatement(itemUPCLookup);
                    //stores the address in the result set
                    rs = ps.executeQuery();
                    while (rs.next()) {
                        name = rs.getString(1);
                        price = rs.getDouble(2);
                        discount = rs.getDouble(3);
                    }

                    //creates a new Item given the grabbed attributes
                    addedItems.getItems().add(new Item(upc, name, price, discount));

                    //blank out the upc text field
                    addItemByUPCTextField.setText("");

                } catch (SQLException e) {
                    mainMenuErrorLabel.setText("Unable to find Item with given upc");
                }
            }
        });
        memeberLookupButton.setOnAction(ActionEvent -> {
            stage.setScene(memberIDScene);
        });

        /*
         * MEMBER ID LOOKUP SCENE
         */
        memberIDGoBackButton.setOnAction(ActionEvent -> {
            stage.setScene(mainScene);
        });
        memberIDEnterButton.setOnAction(ActionEvent -> {
            //reset the error label
            memberIDErrorLabel.setText("");

            //if there's any entered text
            if (phoneNumberTextField.getText().isEmpty() && memberIDTextField.getText().isEmpty()) {
                memberIDErrorLabel.setText("Please enter either a member number or phone number.");

            }
            //if there's a phone number provided
            else if(!phoneNumberTextField.getText().isEmpty()){
                //grabs the phone number
                //also removes all the misc. chars when someone types in a phone number and just keeps the digits
                String phoneNumber = phoneNumberTextField.getText().replaceAll("[^0-9]", "");;

                String memberPhoneLookup = "Call memberPhoneLookup('" + phoneNumber + "')";

                //elements of the member to add
                String accountNum;
                String firstName;
                String lastName;

                try {
                    ps = connection.prepareStatement(memberPhoneLookup);
                    //stores the member in the result set
                    rs = ps.executeQuery();
                    while(rs.next() ) {
                        accountNum = rs.getString(1);
                        firstName = rs.getString(2);
                        lastName = rs.getString(3);
                        //initializes the member using the grabbed attributes
                        givenMember = new Member(accountNum, firstName, lastName);
                    }
                    //shows the membership in the main menu and sets the scene in the main menu
                    mainMenuMemberStatus.setText(givenMember.toString());
                    stage.setScene(mainScene);

                } catch (SQLException e) {
                    memberIDErrorLabel.setText("Unable to find membership with provided phone number");
                }
            }
            //if only the account number is provided
            else {
                //grabs the account number
                String accountNum = memberIDTextField.getText();

                String memberPhoneLookup = "Call memberAccountNumberLookup('" + accountNum + "')";

                //elements of the member to add
                String firstName;
                String lastName;

                try {
                    ps = connection.prepareStatement(memberPhoneLookup);
                    rs = ps.executeQuery();
                    while(rs.next() ) {
                        firstName = rs.getString(1);
                        lastName = rs.getString(2);
                        //initializes the member using the grabbed attributes
                        givenMember = new Member(accountNum, firstName, lastName);
                    }
                    //shows the membership in the main menu and sets the scene in the main menu
                    mainMenuMemberStatus.setText(givenMember.toString());
                    stage.setScene(mainScene);
                }
                catch (SQLException e) {
                    memberIDErrorLabel.setText("Unable to find membership with provided account number");
                }
            }

            //resets the text fields
            phoneNumberTextField.setText("");
            memberIDTextField.setText("");
        });



        stage.setTitle("Hello!");
        stage.show();
    }

    public static void main(String[] args) {
        launch();
    }
}