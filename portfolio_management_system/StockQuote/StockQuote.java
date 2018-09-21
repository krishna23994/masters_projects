package com;

import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URL;

import org.json.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

public class StockQuote {
	
	ServerSocket ss;
	
	public ServerSocket init(int port)
	{
		try {
			ss=new ServerSocket(port);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return ss;
		
	}
	
	public void listen(ServerSocket ss)
	{
		System.out.println("Server Started");
		while(true)
		{
			try {
				
				Socket s=ss.accept();
				DataInputStream dis=new DataInputStream(s.getInputStream());
				DataOutputStream dos=new DataOutputStream(s.getOutputStream());
	            SocketHandleThread sht=new 	SocketHandleThread(s,dis,dos);		
				Thread t=new Thread(sht);
				t.start();
				
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			
			
			
		}
		
		
		
	}
	
	public class SocketHandleThread implements Runnable
	{
        Socket s;
        final DataInputStream dis;
        final DataOutputStream dos;
        
		public SocketHandleThread(Socket s, DataInputStream dis, DataOutputStream dos) {
			
			this.s=s;
			this.dis=dis;
			this.dos=dos;
		}

		@Override
		public void run() {
			
			try {
			getStockQuote(s,dis,dos);
			s.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			
		}

		
		
	}

	public void getStockQuote(Socket s, DataInputStream dis, DataOutputStream dos) {
		
		
		try {
			String line="";
			String request="";
			String quote="";
			request=dis.readUTF();
			
			String[] arr=request.split("\\|");
			JSONArray finalJSON =new JSONArray();
			for(String str:arr)
			{
				
				try {
					JSONObject jsonRes=new JSONObject();
		            URL url = new URL("https://query1.finance.yahoo.com/v8/finance/chart/"+str+"?interval=1m");
		            InputStreamReader inputStream=new InputStreamReader(url.openStream());
		            BufferedReader breader=new BufferedReader(inputStream);
		            String data;
		            String jsonOutput = "";
		            JSONParser parser=new JSONParser();
		            while((data=breader.readLine())!=null)
		            {
		            	jsonOutput+=data;
		            }
		            JSONObject jsonObj=(JSONObject) parser.parse(jsonOutput);
		            JSONObject jsonChart=(JSONObject) jsonObj.get("chart");
		            JSONArray jsonResArr=new JSONArray(String.valueOf(jsonChart.get("result")));
		            org.json.JSONObject jsonIndicators=(org.json.JSONObject) jsonResArr.getJSONObject(0).get("indicators");
		            org.json.JSONObject jsonCurr=(org.json.JSONObject) jsonResArr.getJSONObject(0).get("meta");
		            JSONArray jsonQuoteArr=new JSONArray(String.valueOf(jsonIndicators.get("quote")));
		            JSONArray jsonOpen=new JSONArray(String.valueOf(jsonQuoteArr.getJSONObject(0).get("open")));
		            for(int i=jsonOpen.length()-1;i>=0;i--)
		            {
		            	String val=jsonOpen.getString(i);
		            	if(!val.equals("null"))
		            	{
		            		quote=val;
		            		break;
		            	}
		            }
		            String defCurr= String.valueOf(jsonCurr.get("currency"));
		            jsonRes.put("curr", defCurr);
		            jsonRes.put("sym", str);
		            jsonRes.put("value", quote);
		            finalJSON.put(jsonRes);
		            
		           breader.close();
		            
		        } catch (Exception e) {
		            System.out.println(e.getMessage());
		        }				
				
				
			}
			
				dos.writeUTF(finalJSON.toString());
	           dos.flush();
	            dos.close();
	            dis.close();
			
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		
		
	}

	
	public static void main(String[] args)
	{
		StockQuote stockQuote=new StockQuote();
		ServerSocket ss=stockQuote.init(9090);
		stockQuote.listen(ss);
	}
	
	

}
