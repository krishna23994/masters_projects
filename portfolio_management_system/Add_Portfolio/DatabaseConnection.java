

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DatabaseConnection {

	
	public static Connection getConnection()
	{	Connection conn=null;
		try {
		Class.forName("com.mysql.jdbc.Driver");
		String url = "jdbc:mysql://sql2.njit.edu:3306/database_name";
          conn= DriverManager.getConnection(url, "username", "password");
          conn.setAutoCommit(true);
		 } catch (ClassNotFoundException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		return conn;
	}
	
	public static List<Map<Object,Object>> resultSetToArrayList(ResultSet rs) throws SQLException{
		  ResultSetMetaData md = rs.getMetaData();
		  int columns = md.getColumnCount();
		  List<Map<Object,Object>> list=new ArrayList<>();
		  while (rs.next()){
		     Map<Object,Object> row=new HashMap<>();
		     for(int i=1; i<=columns; ++i){           
		      row.put(md.getColumnName(i),rs.getObject(i));
		     }
		      list.add(row);
		  }

		 return list;
		}
}
