

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.net.ServerSocket;
import java.net.Socket;

/**
 * @author Vishnu Vardhan Karthikeyan(vk442@njit.edu)
 *
 */
public interface ServerInterface {
	public ServerSocket init(int port);

	public void listen(ServerSocket server);

	public void processsRequest(Socket s, DataInputStream dis2, DataOutputStream dos2);

	public void updateClients();

	public String openSession(String clientId, Socket s);

	public String closeSession(String clientId);

	public String sendMessage(String clientId);

	public String getClients(String clientId);


}
