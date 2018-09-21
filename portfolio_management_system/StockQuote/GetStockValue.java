
import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.net.URL;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.List;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

public class GetStockValue {

	public static List<Double> returnPrices(List<String> symbols)
	{
		List<Double> lstVals=new ArrayList<>();
			try {
				List<String> stockVals=new ArrayList<>();
				String sym = String.join("|", symbols);
				
				Socket s = new Socket(InetAddress.getByName("afsaccess1.njit.edu"), 9090);
				DataInputStream dis=new DataInputStream(s.getInputStream());
				DataOutputStream dos=new DataOutputStream(s.getOutputStream());
				dos.writeUTF(sym);
				String response = dis.readUTF();
				JSONArray jsonArr=new JSONArray(response);
				for(int i=0;i<jsonArr.length();i++)
				{
					org.json.JSONObject json=(org.json.JSONObject) jsonArr.get(i);
					String currType=String.valueOf(json.getString("curr"));
					String val=String.valueOf(json.getString("value"));
					if(currType.equals("INR"))
					{
						lstVals.add(exchangeCurrency(currType, "USD", Double.parseDouble(val)));
					}
					else
					{
						lstVals.add(Double.parseDouble(val));
					}
					
				}
				
				
				dis.close();
				dos.close();
				s.close();
				
				
				
			} catch (UnknownHostException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (JSONException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		
		return lstVals;

	}
	
	public static Double exchangeCurrency(String fromCurr, String toCurr, double amount) {
		  double val = 0;
		try {
			
            URL url = new URL("http://api.fixer.io/latest?base="+fromCurr);
            InputStreamReader inputStream=new InputStreamReader(url.openStream());
            BufferedReader breader=new BufferedReader(inputStream);
            JSONParser parser=new JSONParser();
            String data;
            String exchangeRates = "";
            while((data=breader.readLine())!=null)
            {
            	exchangeRates+=data;
            }
            JSONObject json=(JSONObject) parser.parse(exchangeRates);
            JSONObject jsonRates=(JSONObject) parser.parse(String.valueOf(json.get("rates")));
            val=Double.parseDouble(String.valueOf(jsonRates.get(toCurr)))*amount;
            
            breader.close();
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return val;
    }
	
	

}
