module com.example.register_terminal {
    requires javafx.controls;
    requires javafx.fxml;
    requires java.sql;


    opens com.example.register_terminal to javafx.fxml;
    exports com.example.register_terminal;
}