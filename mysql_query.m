function result = mysql_query(host, dbName, queryString)
    % Database parameters
    user = 'username';
    password = 'password';
    % JDBC Parameters
    jdbcString = sprintf('jdbc:mysql://%s/%s', host, dbName);
    jdbcDriver = 'com.mysql.jdbc.Driver';
    javaaddpath('mysql-connector-java-5.1.15-bin.jar');

    % Create the database connection object
    dbConn = database(dbName, user, password, jdbcDriver, jdbcString);

    % Check to make sure that we successfully connected
    if isempty(dbConn.Message)
		if startsWith(upper(string(queryString)), "SELECT")
			result = fetch(dbConn, queryString);
		else
			execute(dbConn, queryString);
		end
    else % If the connection failed, print the error message
        fprintf('Connection failed: %s', dbConn.Message);
    end
    
    % Close the connection so we don't run out of MySQL threads
    close(dbConn);
end