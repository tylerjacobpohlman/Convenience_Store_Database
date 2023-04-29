package com.example.register_terminal;

import javafx.application.Application;
import javafx.event.ActionEvent;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
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
    Connection connection = null;
    PreparedStatement ps;
    ResultSet rs;
    @Override
    public void start(Stage stage) throws IOException {
        AnchorPane introductionPane = new AnchorPane();
        Scene introductionScene = new Scene(introductionPane, 800, 600);

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
        TextField usernameTextField = new TextField();
        AnchorPane.setLeftAnchor(usernameTextField, 40.0);
        AnchorPane.setTopAnchor(usernameTextField, 120.0);
        Label passwordLabel = new Label("Password:");
        AnchorPane.setLeftAnchor(passwordLabel, 40.0);
        AnchorPane.setTopAnchor(passwordLabel, 160.0);
        TextField passwordTextField = new TextField();
        AnchorPane.setLeftAnchor(passwordTextField, 40.0);
        AnchorPane.setTopAnchor(passwordTextField, 180.0);
        Label registerNumLabel = new Label("Register Number:");
        AnchorPane.setLeftAnchor(registerNumLabel, 40.0);
        AnchorPane.setTopAnchor(registerNumLabel, 220.0);
        TextField registerNumTextField = new TextField();
        AnchorPane.setLeftAnchor(registerNumTextField, 40.0);
        AnchorPane.setTopAnchor(registerNumTextField, 240.0);
        Label employeeNumLabel = new Label("Employee ID:");
        AnchorPane.setLeftAnchor(employeeNumLabel, 40.0);
        AnchorPane.setTopAnchor(employeeNumLabel, 280.0);
        TextField employeeNumTextField = new TextField();
        AnchorPane.setLeftAnchor(employeeNumTextField, 40.0);
        AnchorPane.setTopAnchor(employeeNumTextField, 300.0);
        Button introductionEnterButton = new Button("ENTER");
        AnchorPane.setLeftAnchor(introductionEnterButton, 40.0);
        AnchorPane.setTopAnchor(introductionEnterButton, 340.0);
        Label introductionErrorLabel = new Label();
        AnchorPane.setRightAnchor(introductionErrorLabel, 150.0);
        AnchorPane.setBottomAnchor(introductionErrorLabel, 60.0);

        /*
         * INTRODUCTION SCENE
         */
        introductionPane.getChildren().addAll(introductionLabel, introductionSubLabel, usernameLabel, usernameTextField,
                passwordLabel, passwordTextField, registerNumLabel, registerNumTextField, employeeNumLabel,
                employeeNumTextField, introductionEnterButton, introductionErrorLabel);
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
                    String query = "CALL cashierRegisterLogin('" + cashierNum + "', '" + registerNum + "')";
                    ps = connection.prepareStatement(query);
                    ps.execute();
                }
            //any error connecting to the database and/or executing the query
            } catch (SQLException e) {
                //introductionErrorLabel.setText("Error: Username and/or password is incorrect");
                introductionErrorLabel.setText("Error: Unable to establish connection...\n" +
                                               "Ensure the username, password, cashier  \n" +
                                               "ID, and register ID are correct");
            }

        });

        stage.setTitle("Hello!");
        stage.setScene(introductionScene);
        stage.show();
    }

    public static void main(String[] args) {
        launch();
    }
}