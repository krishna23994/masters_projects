package dmsd_project;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class ExpectedReturn {
public static void main(String[] args){
	
	List<Map<Object,Object>> result=new ArrayList<>();
	List<Double> vals=new ArrayList<>();
	try {
		Connection con=DatabaseConnection.getConnection();
		Statement stmt=con.createStatement();
		ResultSet rs=stmt.executeQuery("SELECT COMPANY as comp FROM company_details where COMPANY='APPL' ");
		result=DatabaseConnection.resultSetToArrayList(rs);
		for(Map<Object,Object> map:result)
		{

			double total=0;
			List<String> sym=new ArrayList<>();
			List<Double> eValues=new ArrayList<>();
			String company=String.valueOf(map.get("comp"));
			sym.add(company);
			vals=GetStockValue.returnPrices(sym);
			
			for(int i=1;i<vals.size();i++)
			{
			System.out.println((vals.get(i)-vals.get(i-1))/vals.get(i-1));
			eValues.add(((vals.get(i)-vals.get(i-1))/vals.get(i-1))*100);
                
			}
			
		for(double d:eValues)
		{
			//System.out.println(d);
			total+=d;
		}
		
		double expected=total/eValues.size();
		if(!Double.isNaN(expected))
		{
			int update=stmt.executeUpdate("UPDATE company_details SET EXPECTED_RETURN='"+expected+"' where COMPANY='"+company+"'");
			
		}
		else
		{
			int update=stmt.executeUpdate("UPDATE company_details SET EXPECTED_RETURN='0.455342' where COMPANY='"+company+"'");
		}
		
		System.out.println("UPDATE company_details SET EXPECTED_RETURN='"+expected+"' where COMPANY='"+company+"'");
		
		}
		
		
		
		
	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	
	
}
}
