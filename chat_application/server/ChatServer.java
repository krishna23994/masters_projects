

import java.net.ServerSocket;
import java.net.Socket;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Scanner;
import java.util.Set;
import java.util.StringTokenizer;

import org.json.JSONException;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.io.*;


/**
 * @author Vishnu Vardhan Karthikeyan(vk442@njit.edu)

 *
 */
public class ChatServer implements ServerInterface {

	ServerSocket ss;
	static int clientCount = 0;
	/**
	 * contains the client details like id,ipAddress,Socket
	 */
	public static Set<ClientDetails> clients = Collections.synchronizedSet(new HashSet<>());
	/**
	 * contains the connected clients
	 */
	public static Set<ClientConnection> connectedclients = Collections.synchronizedSet(new HashSet<>());

	/*
	 * Create Server Socket at given port
	 *
	 * @see project.ServerInterface#init(int)
	 */
	@Override
	public ServerSocket init(int port) {
		try {
			ss = new ServerSocket(port);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		return ss;

	}

	/*
	 * Listen to the incoming connections from the client
	 *
	 * @see project.ServerInterface#listen()
	 */
	@Override
	public void listen(ServerSocket server) {
		while (true) {
			try {
				// Accept new client request
				System.out.println("Server started");
				Socket s = ss.accept();
				System.out.println("New client request received : " + s);
				DataInputStream dis = new DataInputStream(s.getInputStream());
				DataOutputStream dos = new DataOutputStream(s.getOutputStream());
				ClientHandler mtch = new ClientHandler(s, dis, dos);
				Thread t = new Thread(mtch);
				t.start();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

		}
	}

	/*
	 * Process the request form client whether it is open,close,send message
	 *
	 * @see project.ServerInterface#processsRequest()
	 */
	@Override
	public  void processsRequest(Socket s, DataInputStream dis2, DataOutputStream dos2) {
		try {

			String incomingMsg = dis2.readUTF();
			JSONParser parser = new JSONParser();
			JSONObject json = (JSONObject) parser.parse(incomingMsg);
			String command = String.valueOf(json.get("command"));
			String status;
			JSONObject response = new JSONObject();
			switch (ChatCommand.valueOf(command)) {
			case OPEN:
				status = openSession(String.valueOf(json.get("sender")), s);
				response.put("command",ChatCommand.OPEN.name());
				response.put("status", status);
				break;
			case CLOSE:
				status = closeSession(String.valueOf(json.get("sender")));
				response.put("command",ChatCommand.CLOSE.name());
				response.put("status", status);
				break;
			case CONNECT:
				status = establishConnection(json.toJSONString());
				response.put("command",ChatCommand.CONNECT.name());
				response.put("status", status);
				break;
			case MESSAGE:
				status = sendMessage(json.toJSONString());
				response.put("command","OUT_MESSAGE");
				response.put("status", status);
				break;
			case CLIENTS:
				status = getClients(String.valueOf(json.get("sender")));
				response.put("command",ChatCommand.CLIENTS.name());
				response.put("clients", status);
				break;

			}

			dos2.writeUTF(response.toJSONString());


		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	private String establishConnection(String connect) {
		JSONParser parser = new JSONParser();
		try {
			JSONObject json = (JSONObject) parser.parse(connect);
			ClientConnection clientConnection = new ClientConnection();
			for (ClientDetails client : clients) {
				if (client.getClientId().equals(String.valueOf(json.get("sender")))) {
					clientConnection.setSender(client);
				}
				if (client.getClientId().equals(String.valueOf(json.get("receiver")))) {
					clientConnection.setReceiver(client);
				}
			}
			if(!connectedclients.contains(clientConnection))
			{
			connectedclients.add(clientConnection);
			return "success";
			}

		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return "failure";

		// TODO Auto-generated method stub

	}

	/*
	 * Update the list of clients once it is connected in clients Set
	 *
	 * @see project.ServerInterface#updateConnections()
	 */
	@Override
	public void updateClients() {

	}

	/*
	 * Handles send message request from client
	 *
	 * @see project.ServerInterface#sendMessage(java.lang.String)
	 */
	@Override
	public String sendMessage(String json) {
		try {
			ClientConnection clientConnection = new ClientConnection();
			ClientConnection clientConnection2 = new ClientConnection();
			JSONParser parser = new JSONParser();
			JSONObject jsonObj = (JSONObject) parser.parse(json);
			String sender = String.valueOf(jsonObj.get("sender"));
			String receiver = String.valueOf(jsonObj.get("receiver"));
			for (ClientDetails c : clients) {
				if (c.getClientId().equals(sender)) {
					clientConnection.setSender(c);
					clientConnection2.setReceiver(c);
				}
				if (c.getClientId().equals(receiver)) {
					clientConnection.setReceiver(c);
					clientConnection2.setSender(c);
				}
			}
			if(connectedclients.contains(clientConnection)&&connectedclients.contains(clientConnection2))
			{
				Socket s = clientConnection.getReceiver().getSocket();
				DataOutputStream dos = new DataOutputStream(s.getOutputStream());
				dos.writeUTF(jsonObj.toJSONString());
				return "success";
			}

			/*for (ClientConnection connection : connectedclients) {
				if (connection.equals(clientConnection)) {


				}
			}*/


		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		return "failure";
	}

	@Override
	public String openSession(String clientId, Socket s) {
		ClientDetails client = new ClientDetails();
		client.setClientId(clientId);
		client.setSocket(s);
		for (ClientDetails c : clients) {
			if (c.getClientId().equals(clientId)) {
				return "failure";
			}
		}
		clients.add(client);
		return "success";
	}

	@Override
	public String closeSession(String clientId) {
		String checkClient=clientId;
		String receiverId;
		if(checkClient.contains("end_session"))
		{
			clientId=checkClient.split("\\|")[0];
			receiverId=checkClient.split("\\|")[1];
			Iterator<ClientConnection> iterator1 = connectedclients.iterator();
			while (iterator1.hasNext()) {
				ClientConnection clientConnection = iterator1.next();
				if (clientConnection.getSender().getClientId().equals(clientId)&&clientConnection.getReceiver().getClientId().equals(receiverId)) {
					iterator1.remove();
				}

			}
		}
		else
		{
		ClientDetails client = new ClientDetails();
		Iterator<ClientDetails> iterator = clients.iterator();
		while (iterator.hasNext()) {
			ClientDetails cl = iterator.next();
			if (cl.getClientId().equals(clientId)) {
				iterator.remove();
			}
		}
		}



		return "success";
	}

	@Override
	public String getClients(String clientId) {
		StringBuilder builder = new StringBuilder();
		for (ClientDetails clientDetails2 : clients) {
			if (!clientDetails2.getClientId().equals(clientId)) {
				builder.append(clientDetails2.getClientId() + "|");
			}
		}
		return builder.toString();
	}

	class ClientHandler implements Runnable {

		final DataInputStream dis;
		final DataOutputStream dos;
		Socket s;

		// constructor
		public ClientHandler(Socket s, DataInputStream dis, DataOutputStream dos) {
			this.dis = dis;
			this.dos = dos;
			this.s = s;
		}

		@Override
		public void run() {

			while (true) {

				processsRequest(this.s, this.dis, this.dos);
			}
		}
	}

	public static void main(String args[]) {
		ChatServer ss = new ChatServer();
		ServerSocket server = ss.init(8088);
		ss.listen(server);

	}

}
