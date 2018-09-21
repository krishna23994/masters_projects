

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.Socket;
import java.util.Set;
import java.util.concurrent.LinkedBlockingQueue;

import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

/**
 * @author Krishna Murali (km572@njit.edu)
 *
 */

public class ChatClient implements ClientInterface {

	public String clientId;
	Socket clientSocket;
	public static DataInputStream dataInputStream;
	public static DataOutputStream dataOutputStream;
	public String openSessionStatus;
	public String closeSessionStatus;
	public LinkedBlockingQueue<JSONObject> messages = new LinkedBlockingQueue<>();;
	public String outgoingMessage;
	public String connectionStatus;
	public String clients;

	/*
	 * To check the status of the server
	 *
	 * @see project.ClientInterface#serverStatus()
	 */
	@Override
	public boolean serverStatus() {
		boolean bool = false;
		try {
			clientSocket = new Socket("localhost", 8088);
			dataOutputStream = new DataOutputStream(clientSocket.getOutputStream());
			dataInputStream = new DataInputStream(clientSocket.getInputStream());
			bool = clientSocket.isConnected();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		// TODO Auto-generated method stub
		return bool;
	}

	/*
	 * To connect a client to server using client Id
	 *
	 * @see project.ClientInterface#clientConnect(java.lang.String)
	 */
	@Override
	public String clientConnect(String json) {

		try {
			dataOutputStream.writeUTF(json);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		return null;
	}

	/*
	 * Handles @open <client id> request from the client and opens chat window
	 *
	 * @see project.ClientInterface#openSession(java.lang.String)
	 */
	@Override
	public String openSession(String clientId) {
		try {
			ReadMessage message = new ReadMessage(clientSocket, dataInputStream, dataOutputStream);
			Thread t = new Thread(message);
			t.start();
			JSONObject json = new JSONObject();
			json.put("sender", clientId);
			json.put("command", ChatCommand.OPEN.name());
			System.out.println(dataOutputStream);
			dataOutputStream.writeUTF(json.toJSONString());
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		return null;
	}

	/*
	 * Handles @close <client id> request from the client
	 *
	 * @see project.ClientInterface#closeSession(java.lang.String)
	 */
	@Override
	public String closeSession(String clientId) {
		try {
			JSONObject json = new JSONObject();
			json.put("sender", clientId);
			json.put("command", ChatCommand.CLOSE.name());
			System.out.println(dataOutputStream);
			dataOutputStream.writeUTF(json.toJSONString());
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return null;
	}

	/*
	 * Gets the list of connected clients
	 *
	 * @see project.ClientInterface#getClients()
	 */
	@Override
	public String getClients() {
		try {
			JSONObject json = new JSONObject();
			json.put("sender", clientId);
			json.put("command", ChatCommand.CLIENTS.name());
			System.out.println(dataOutputStream);
			dataOutputStream.writeUTF(json.toJSONString());
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return null;
	}

	/*
	 * Send message to the connected client
	 *
	 * @see project.ClientInterface#sendMessage(java.lang.String)
	 */
	@Override
	public void sendMessage(String json) {

		try {
			dataOutputStream.writeUTF(json);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	class ReadMessage implements Runnable {

		final DataInputStream dis;
		final DataOutputStream dos;
		Socket s;

		// constructor
		public ReadMessage(Socket s, DataInputStream dis, DataOutputStream dos) {
			this.dis = dis;
			this.dos = dos;
			this.s = s;
		}

		@Override
		public void run() {

			while (true) {
				try {
					while (dis.available() > 0) {
						String read = dis.readUTF();
						JSONParser parser = new JSONParser();
						JSONObject json = (JSONObject) parser.parse(read);
						String command = String.valueOf(json.get("command"));
						switch (ChatCommand.valueOf(command)) {
						case OPEN:
							openSessionStatus = String.valueOf(json.get("status"));
							break;
						case CLOSE:
							closeSessionStatus = String.valueOf(json.get("status"));
							break;
						case CONNECT:
							connectionStatus = String.valueOf(json.get("status"));
							break;
						case OUT_MESSAGE:
							outgoingMessage = String.valueOf(json.get("status"));
							break;
						case MESSAGE:
							messages.add(json);
							break;
						case CLIENTS:
							clients = String.valueOf(json.get("clients"));
							break;

						}

					}
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} catch (ParseException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}

			}
		}
	}

}
