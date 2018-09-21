

import java.util.Set;

/**
 * @author Krishna Murali(km572@njit.edu)
 *
 */
public interface ClientInterface {
	public boolean serverStatus();

	public String clientConnect(String clientId);

	public String openSession(String clientId);

	public String closeSession(String clientId);

	public void sendMessage(String clientId);

	public String getClients();
}
