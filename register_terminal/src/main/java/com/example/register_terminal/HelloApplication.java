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
    String cashierNum;
    String registerNum;
    Connection connection;
    PreparedStatement ps;
    ResultSet rs;

    //stores memberID for future use
    String memberID = null;

    @Override
    public void start(Stage stage) throws IOException {
        AnchorPane introductionPane = new AnchorPane();
        Scene introductionScene = new Scene(introductionPane, 800, 600);

        AnchorPane mainPane = new AnchorPane();
        Scene mainScene = new Scene(mainPane, 800, 600);

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

        /*
         * INTRODUCTION SCENE
         */
        introductionPane.getChildren().addAll(introductionLabel, introductionSubLabel, usernameLabel, usernameTextField,
                passwordLabel, passwordTextField, registerNumLabel, registerNumTextField, employeeNumLabel,
                employeeNumTextField, introductionEnterButton, introductionErrorLabel, mainMenuErrorLabel);
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
                    mainPane.getChildren().addAll(addressLabel, addedItems, addItemByUPCLabel, addItemByUPCTextField,
                            addItemByUPCButton, memeberLookupButton, itemLookupButton, finishAndPayButton);
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
                while(rs.next() ) {
                    name = rs.getString(1);
                    price = rs.getDouble(2);
                    discount = rs.getDouble(3);
                }

                //creates a new Item given the grabbed attributes
                addedItems.getItems().add(new Item(upc, name, price, discount) );


            } catch (SQLException e) {
                mainMenuErrorLabel.setText("Error: Unable to find Item with given upc");
            }

        });

        stage.setTitle("Hello!");
        stage.show();
    }

    public static void main(String[] args) {
        launch();
    }
}