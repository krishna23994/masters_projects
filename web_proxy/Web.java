import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.UnknownHostException;

public class Web {
	public static char[] link1 = new char[] { 't', 'o', 'r', 'r', 'e', 'n', 't', 'z', '.', 'e', 'u' };
	public static char[] link2 = new char[] { 'm', 'a', 'k', 'e', 'm', 'o', 'n', 'e', 'y', '.', 'c', 'o', 'm' };
	public static char[] link3 = new char[] { 'l', 'o', 't', 't', 'o', 'f', 'o', 'r', 'e', 'v', 'e', 'r', '.', 'c', 'o',
			'm' };
	public static char[] link4 = new char[] { 'w', 'w', 'w', '.', 't', 'o', 'r', 'r', 'e', 'n', 't', 'z', '.', 'e',
			'u' };
	public static char[] link5 = new char[] { 'w', 'w', 'w', '.', 'm', 'a', 'k', 'e', 'm', 'o', 'n', 'e', 'y', '.', 'c',
			'o', 'm' };
	public static char[] link6 = new char[] { 'w', 'w', 'w', '.', 'l', 'o', 't', 't', 'o', 'f', 'o', 'r', 'e', 'v', 'e',
			'r', '.', 'c', 'o', 'm' };

	public static void main(String[] args) {
		int port = Integer.parseInt(args[0]);
		ServerSocket socket = init(port);
		go(socket);
	}

	/**
	 * Bind a port to socket
	 *
	 * @author Ravali
	 * @param port
	 * @return socket
	 */
	public static ServerSocket init(int port) {
		ServerSocket socket = null;
		try {
			socket = new ServerSocket();
			socket.bind(new InetSocketAddress(port));
			System.out.println("CS656 project by group WG6");

		} catch (IOException e) {
			e.printStackTrace();
		}

		return socket;

	}

	/**
	 * Process the requested website in the browser
	 *
	 * @author Krishna
	 * @param socket
	 */
	private static void go(ServerSocket socket) {
		try {
			while (true) {
				Socket ClientSocket = socket.accept();
				byte[] request = new byte[65536];
				byte[] response = new byte[65536];
				int s;
				while ((s = ClientSocket.getInputStream().read(request, 0, request.length)) != -1) {
					if (endOfRequest(request) == true)
						break;

				}

				Socket server = new Socket(dnslookup(parse(request, request.length)), 80);
				server.getOutputStream().write(request, 0, request.length);
				server.getOutputStream().flush();
				System.out.println("LOG: request for (" + parse(request, request.length) + ") processed");
				while ((s = server.getInputStream().read(response, 0, response.length)) != -1) {
					ClientSocket.getOutputStream().write(response, 0, s);
					ClientSocket.getOutputStream().flush();
					// System.out.println("Wrote to client: " + s + " bytes");

				}
				ClientSocket.getOutputStream().close();

			}
		} catch (UnknownHostException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (NullPointerException e) {
			e.printStackTrace();
		} catch (Exception e) {
			e.printStackTrace();
		}

	}

	/**
	 * Get the ip address of the requested website
	 *
	 * @author Nikhil and Sneh
	 * @param parse
	 * @return inetAddress
	 */
	private static InetAddress dnslookup(String url) {
		InetAddress ipAddr = null;
		try {

			InetAddress[] inetAddr = InetAddress.getAllByName(url);
			ipAddr = inetAddr[0];

		} catch (UnknownHostException e) {
			e.printStackTrace();
		}

		return ipAddr;
	}

	/**
	 * Parse the http request to get the URL
	 *
	 * @author Krishna
	 * @param request
	 * @param n
	 * @return url
	 */
	public static String parse(byte[] request, int n) {
		char[] input = new char[65536];
		for (int i = 0; i < n; i++) {
			input[i] = (char) request[i];

		}
		char[] urlBackup = new char[70];
		char[] url = null;
		for (int i = 0; i < input.length; i++) {

			if (input[i] == 'H' && input[i + 1] == 'o' && input[i + 2] == 's' && input[i + 3] == 't'
					&& input[i + 4] == ':' && input[i + 5] == ' ') {

				int j = i + 6;
				int k = 0;
				while (input[j] != '\r') {
					urlBackup[k] = input[j];
					j++;
					k++;
				}
				url = new char[k];
				for (int l = 0; l < url.length; l++) {
					url[l] = urlBackup[l];
				}
				break;
			}

		}

		for (int i = 0; i < url.length; i++) {
			if ((int) url[i] != 0) {
				if (url[i] == '4' && url[i + 1] == '4' && url[i + 2] == '3') {
					System.out.println("Supports http links only");

				}
			}
		}

		if (checkWebsite(link1, urlBackup) || checkWebsite(link2, urlBackup) || checkWebsite(link3, urlBackup)
				|| checkWebsite(link4, urlBackup) || checkWebsite(link5, urlBackup) || checkWebsite(link6, urlBackup)) {
			System.out.println("Cannot forward this request");
			url = null;

		}

		return new String(url);
	}

	/**
	 * Check requested url with blocked urls
	 *
	 * @author Harshil and Sneh
	 * @param link
	 * @param url
	 * @return true or false
	 */
	private static boolean checkWebsite(char[] link, char[] url) {
		int count = 0;
		for (int i = 0; i < link.length; i++) {
			if (url[i] == link[i]) {

				count++;
			}
		}

		if (count == link.length) {
			return true;
		} else {

			return false;
		}

	}

	/**
	 * To check the end of http request
	 *
	 * @author Ravali
	 * @param data
	 * @return
	 * @throws Exception
	 */
	public static boolean endOfRequest(byte[] data) throws Exception {

		for (int i = 0; i < data.length; i++) {
			if (!Byte.toString(data[i]).equals("0")) {
				if ((Byte.toString(data[i]).equals("13")) && (Byte.toString(data[(i + 1)]).equals("10"))
						&& (Byte.toString(data[(i + 2)]).equals("13")) && (Byte.toString(data[(i + 3)]).equals("10")))
					return true;
			}
		}
		return false;
	}
}
