
/**
 * @author Vishnu Vardhan Karthikeyan(vk442@njit.edu
 *
 */

public enum ChatCommand {
	/**
	 * Commands for chat server application
	 */
	OPEN, CLOSE, MESSAGE,CLIENTS, CONNECT,OUT_MESSAGE;


	public String toString() {
		return this.name();
	}
}
