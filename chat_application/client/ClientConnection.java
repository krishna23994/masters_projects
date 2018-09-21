


/**
 * @author Krishna Murali(km572@njit.edu)

 *
 */
public class ClientConnection {
	public ClientDetails sender;
	public ClientDetails receiver;

	public ClientDetails getSender() {
		return sender;
	}

	public void setSender(ClientDetails sender) {
		this.sender = sender;
	}

	public ClientDetails getReceiver() {
		return receiver;
	}

	public void setReceiver(ClientDetails receiver) {
		this.receiver = receiver;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((receiver == null) ? 0 : receiver.hashCode());
		result = prime * result + ((sender == null) ? 0 : sender.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		ClientConnection other = (ClientConnection) obj;
		if (receiver == null) {
			if (other.receiver != null)
				return false;
		} else if (!receiver.equals(other.receiver))
			return false;
		if (sender == null) {
			if (other.sender != null)
				return false;
		} else if (!sender.equals(other.sender))
			return false;
		return true;
	}



}
