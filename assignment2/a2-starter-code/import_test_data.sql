SET SEARCH_PATH TO Library;

-- Import Data for Holding
\Copy Holding FROM 'test/Holding.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Contributor
\Copy Contributor FROM 'test/Contributor.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for HoldingContributor
\Copy HoldingContributor FROM 'test/HoldingContributor.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Ward
\Copy Ward FROM 'test/Ward.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryBranch
\Copy LibraryBranch FROM 'test/LibraryBranch.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryRoom
\Copy LibraryRoom FROM 'test/LibraryRoom.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryHours
\Copy LibraryHours FROM 'test/LibraryHours.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryCatalogue
\Copy LibraryCatalogue FROM 'test/LibraryCatalogue.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryHolding
\Copy LibraryHolding FROM 'test/LibraryHolding.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryEvent
\Copy LibraryEvent FROM 'test/LibraryEvent.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventAgeGroup
\Copy EventAgeGroup FROM 'test/EventAgeGroup.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventSubject
\Copy EventSubject FROM 'test/EventSubject.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventSchedule
\Copy EventSchedule FROM 'test/EventSchedule.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Patron
\Copy Patron FROM 'test/Patron.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Checkout
\Copy Checkout FROM 'test/Checkout.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Return
\Copy Return FROM 'test/Return.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Review
\Copy Review FROM 'test/Review.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for RoomBooking
\Copy RoomBooking FROM 'test/RoomBooking.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventSignUp
\Copy EventSignUp FROM 'test/EventSignUp.csv' With CSV DELIMITER ',' HEADER;
