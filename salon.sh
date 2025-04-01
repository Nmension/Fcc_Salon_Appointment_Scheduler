#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"
echo -e "\n~~~~~ MY SALON ~~~~~\n"

MAIN_MENU() {
  #if the Service selected doesn't exist in the salon db or isn't a number, continue the loop
  until [[ (! -z $SELECTED_SERVICE_NAME)  && $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  do
    # if it's not the first time the MAIN_MENU func runs, print the second arg as title else the Main title
    if [[ $1 ]]
    then
      echo -e "\n$1"
    else
      echo -e "Welcome to My Salon, how can I help you?\n"
    fi
    #query the db for the list of services and their ID
    SERVICES=$($PSQL "SELECT * FROM services;")
    #read the results of the query and format them
    echo "$SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
    do
      echo "$SERVICE_ID) $SERVICE_NAME"
    done
    #save in a var the stdin from the user
    read SERVICE_ID_SELECTED
    #var to check if the selected service exists in the DB
    SELECTED_SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED;")
    #redirect the user according to his inputed choice
    case $SERVICE_ID_SELECTED in
      #valid choices
      1 | 2 | 3 | 4) APPOINTEMENT_MENU ;;
      #recall the func if the input is not a valid number with a second arg
      *) MAIN_MENU "I could not find that service. What would you like today?" ;;
    esac
  done
}

APPOINTEMENT_MENU() {
  #ask for phone number
  echo -e "\nWhat's your phone number?"
  #wait for user input
  read CUSTOMER_PHONE
  #check if the user exists through his phone number
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  #format the service name using sed in a a subshell then save it into a variable
  FORMATTED_SELECTED_SERVICE_NAME=$( echo $SELECTED_SERVICE_NAME | sed 's/^ $//')
  #if not found so the var is empty
  if [[ -z $CUSTOMER_NAME ]]
  then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    #wait for the new name input
    read CUSTOMER_NAME
    #insert new customer info into the customers db
    INSERT_CUSTOMER_INFO=$($PSQL "INSERT INTO customers(phone,name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME');")
  fi
  #format the new/existing customer name
  FORMATTED_CUSTOMER_NAME=$(echo $CUSTOMER_NAME | sed 's/^ $//')
  #ask for time
  echo -e "\nWhat time would you like your $FORMATTED_SELECTED_SERVICE_NAME, $FORMATTED_CUSTOMER_NAME?"
  #wait for user input
  read SERVICE_TIME
  #find existing customer_id thrgh the inputed unique phone number
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  # insert data into appointment table
  INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');")
  echo -e "\nI have put you down for a $FORMATTED_SELECTED_SERVICE_NAME at $SERVICE_TIME, $FORMATTED_CUSTOMER_NAME."
}
MAIN_MENU