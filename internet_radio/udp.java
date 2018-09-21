import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;
import java.net.UnknownHostException;

public class udp {
	public static void main(String[] args) {
		try {
			DatagramSocket datagramSocket = new DatagramSocket();
			File file = new File(args[2]);
			FileInputStream fileInputStream = new FileInputStream(file);
			int pktSize = Integer.parseInt(args[3]);
			double nosPkts = Math.ceil((int) file.length() / pktSize);
			for (double i = 0; i < nosPkts + 1; i++) {
				byte[] buf = new byte[Integer.parseInt(args[5])];
				fileInputStream.read(buf, 0, buf.length);
				DatagramPacket datagramPacket = new DatagramPacket(buf, buf.length, InetAddress.getByName(args[0]),
				Integer.parseInt(args[1]));
				Thread.sleep(Long.parseLong(args[4]));
				datagramSocket.send(datagramPacket);
			}
		} catch (SocketException e) {
			e.printStackTrace();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (UnknownHostException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}

	}

}
