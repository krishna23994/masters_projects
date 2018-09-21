

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.Frame;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Toolkit;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.WindowEvent;
import java.awt.event.WindowListener;
import java.util.HashMap;
import java.util.Map;

import javax.swing.*;
import org.json.simple.JSONObject;

/**
 * @author Krishna Murali (km572@njit.edu)
 *
 */
public class ChatClientUI implements ActionListener {
	ChatClientUI mainGUI;
	JFrame mainFrame = new JFrame("Pesuvom");
	JFrame mainFrame1 = new JFrame();
	DefaultListModel defaultListModel = new DefaultListModel<>();
	ChatClient chatClient = new ChatClient();
	Object[] data;
	JList list = new JList(defaultListModel);;
	JButton sendMessage;
	JTextField messageBox;
	JTextArea chatBox;
	JTextField userName;
	JFrame preFrame;
	String username;
	Dimension dim = Toolkit.getDefaultToolkit().getScreenSize();
	static String status;
	static Map<String,JTextArea> chat=new HashMap<>();
	static Map<String,JTextField> message=new HashMap<>();
	public static void main(String[] args) {
		ChatClientUI mainGUI = new ChatClientUI();
		ChatClient chat = new ChatClient();
		if (chat.serverStatus()) {
			status = "Server Up";
		} else {
			status = "Server Down";
		}
		mainGUI.loginPanel();
	}

	public void loginPanel() {
		mainFrame.setVisible(false);
		preFrame = new JFrame("Pesuvom");
		preFrame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		userName = new JTextField(20);
		JLabel chooseUsernameLabel = new JLabel("Enter your Email or UCID");
		JLabel serverStatus = new JLabel();
		JLabel serverLabel = new JLabel("Server Status: ");
		JPanel serverStatusPanel = new JPanel();
		serverStatus.setText(status);
		serverStatusPanel.add(serverLabel);
		serverStatusPanel.add(serverStatus);
		serverStatusPanel.setBounds(250, 100, 50, 50);
		JButton enterServer = new JButton("Login");
		JPanel prePanel = new JPanel(new FlowLayout());
		prePanel.add(chooseUsernameLabel);
		prePanel.add(userName);
		prePanel.add(enterServer);
		prePanel.add(serverStatusPanel);
		preFrame.add(prePanel);
		preFrame.setVisible(true);
		preFrame.setSize(500, 200);
		preFrame.setLocation(dim.width / 2 - preFrame.getSize().width / 2,
				dim.height / 2 - preFrame.getSize().height / 2);
		enterServer.addActionListener(new ActionListener() {

			@Override
			public void actionPerformed(ActionEvent e) {
				username = userName.getText();
				if (username.length() < 1) {
					JOptionPane.showMessageDialog(preFrame, "Invalid Username", "Error", JOptionPane.ERROR_MESSAGE);
				}

				else if (!chatClient.serverStatus()) {

					JOptionPane.showMessageDialog(preFrame, "Sorry, Server Down", "Error", JOptionPane.ERROR_MESSAGE);

				}

				else {

					chatClient.clientId = username;
					chatClient.openSession(username);
					while (chatClient.openSessionStatus == null) {
						try {
							Thread.sleep(1000);
						} catch (InterruptedException e1) {
							// TODO Auto-generated catch block
							e1.printStackTrace();
						}
					}
					if(chatClient.openSessionStatus.equals("failure"))
					{
						JOptionPane.showMessageDialog(preFrame, "Sorry, Take different user name", "Error", JOptionPane.ERROR_MESSAGE);
					}
					else {
					chatClient.openSessionStatus=null;
					preFrame.setVisible(false);
					refreshClients();
					userScreen();

					}
				}

			}
		});
	}

	public void userScreen() {
		mainFrame.setVisible(true);
		list.setSelectionMode(ListSelectionModel.SINGLE_INTERVAL_SELECTION);
		list.setLayoutOrientation(JList.VERTICAL);
		list.setVisibleRowCount(-1);
		JScrollPane listScroller = new JScrollPane(list);
		listScroller.setPreferredSize(new Dimension(250, 80));
		JButton connect = new JButton("Connect");
		JButton refresh = new JButton("Refresh");
		JButton close = new JButton("Disconnect");
		connect.addActionListener(this);
		refresh.addActionListener(this);
		close.addActionListener(this);
		connect.setActionCommand("connect");
		refresh.setActionCommand("refresh");
		close.setActionCommand("close");
		JPanel userPanel = new JPanel(new FlowLayout());
		userPanel.add(listScroller);
		userPanel.add(connect);
		userPanel.add(refresh);
		userPanel.add(close);
		mainFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		mainFrame.add(userPanel);
		mainFrame.setSize(600, 200);
		mainFrame.setLocation(dim.width / 2 - mainFrame.getSize().width / 2,
				dim.height / 2 - mainFrame.getSize().height / 2);
		mainFrame.addWindowListener(new WindowListener() {

			@Override
			public void windowOpened(WindowEvent e) {
				// TODO Auto-generated method stub

			}

			@Override
			public void windowIconified(WindowEvent e) {
				// TODO Auto-generated method stub

			}

			@Override
			public void windowDeiconified(WindowEvent e) {
				// TODO Auto-generated method stub

			}

			@Override
			public void windowDeactivated(WindowEvent e) {
				// TODO Auto-generated method stub

			}

			@Override
			public void windowClosing(WindowEvent e) {
				System.out.println("Window_Main closing");
				chatClient.closeSession(username);

			}

			@Override
			public void windowClosed(WindowEvent e) {
				// TODO Auto-generated method stub

			}

			@Override
			public void windowActivated(WindowEvent e) {
				// TODO Auto-generated method stub

			}
		});
	}

	public void mainScreen(JFrame frame) {
		frame.setVisible(true);
		frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		JPanel southPanel = new JPanel();
		frame.add(BorderLayout.SOUTH, southPanel);
		southPanel.setBackground(Color.BLUE);
		southPanel.setLayout(new GridBagLayout());

		messageBox = new JTextField(30);

		sendMessage = new JButton("Send Message");
		chatBox = new JTextArea();
		chatBox.setEditable(false);
		frame.add(new JScrollPane(chatBox), BorderLayout.CENTER);
		chatBox.setLineWrap(true);

		GridBagConstraints left = new GridBagConstraints();
		left.anchor = GridBagConstraints.WEST;
		GridBagConstraints right = new GridBagConstraints();
		right.anchor = GridBagConstraints.EAST;
		right.weightx = 2.0;

		southPanel.add(messageBox, left);
		southPanel.add(sendMessage, right);

		chatBox.setFont(new Font("Serif", Font.PLAIN, 15));
		sendMessage.addActionListener(this);
		sendMessage.setActionCommand("send|" + frame.getTitle());
		frame.setSize(500, 500);
		message.put(chatClient.clientId+"|"+frame.getTitle(), messageBox);
		chat.put(chatClient.clientId+"|"+frame.getTitle(), chatBox);
		frame.addWindowListener(new WindowListener() {

			@Override
			public void windowOpened(WindowEvent e) {
				// TODO Auto-generated method stub

			}

			@Override
			public void windowIconified(WindowEvent e) {
				// TODO Auto-generated method stub

			}

			@Override
			public void windowDeiconified(WindowEvent e) {
				// TODO Auto-generated method stub

			}

			@Override
			public void windowDeactivated(WindowEvent e) {
				// TODO Auto-generated method stub

			}

			@Override
			public void windowClosing(WindowEvent e) {
				System.out.println("Window Closing");
				chatClient.closeSession(chatClient.clientId+"|"+frame.getTitle()+"|"+"end_session");
				message.remove(chatClient.clientId+"|"+frame.getTitle());
				chat.remove(chatClient.clientId+"|"+frame.getTitle());

			}

			@Override
			public void windowClosed(WindowEvent e) {
				// TODO Auto-generated method stub

			}

			@Override
			public void windowActivated(WindowEvent e) {
				// TODO Auto-generated method stub

			}
		});
	}

	public void refreshClients() {
		chatClient.getClients();
		while (chatClient.clients == null) {
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}
		}
		String getClients = chatClient.clients;
		chatClient.clients = null;
		if (getClients != null) {
			String[] clients = getClients.split("\\|");
			defaultListModel.removeAllElements();
			for (String str : clients) {
				int pos = list.getModel().getSize();
				defaultListModel.add(pos, str);

			}
		}

	}

	@Override
	public void actionPerformed(ActionEvent e) {
		String command = e.getActionCommand();
		if (command.equals("close")) {
			chatClient.closeSession(username);
			while (chatClient.closeSessionStatus == null) {
				try {
					Thread.sleep(1000);
				} catch (InterruptedException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
			}
			mainFrame.setVisible(false);

		} else if (command.equals("refresh")) {
			refreshClients();

		}

		else if (command.equals("connect")) {
			String receiver = String.valueOf(list.getSelectedValue());
			if (receiver.equals("null")) {
				JOptionPane.showMessageDialog(mainFrame, "Select a user", "Error", JOptionPane.ERROR_MESSAGE);
			} else {
				JSONObject json = new JSONObject();
				json.put("sender", chatClient.clientId);
				json.put("command", ChatCommand.CONNECT.name());
				json.put("receiver", receiver);
				chatClient.clientConnect(json.toJSONString());
				while (chatClient.connectionStatus == null) {
					try {
						Thread.sleep(1000);
					} catch (InterruptedException e1) {
						// TODO Auto-generated catch block
						e1.printStackTrace();
					}
				}
				if(chatClient.connectionStatus.equals("success")) {
				JFrame chatSession = new JFrame(receiver);
				MyMessage message = new MyMessage();
				Thread t = new Thread(message);
				t.start();
				mainScreen(chatSession);
				}
				chatClient.connectionStatus = null;


			}
		}

		else if (command.contains("send")) {
			String receiver = command.split("\\|")[1];
			JTextField messageBox=message.get(chatClient.clientId+"|"+receiver);
			JSONObject json = new JSONObject();
			json.put("sender", chatClient.clientId);
			json.put("receiver", receiver);
			json.put("message", messageBox.getText());
			json.put("command", ChatCommand.MESSAGE.name());
			chatClient.sendMessage(json.toJSONString());
			while (chatClient.outgoingMessage == null) {
				try {
					Thread.sleep(1000);
				} catch (InterruptedException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
			}
			chatClient.outgoingMessage = null;
			JTextArea chatBox=chat.get(chatClient.clientId+"|"+receiver);
			chatBox.append(chatClient.clientId + " :" + messageBox.getText() + "\n");
			messageBox.setText("");

		}

	}

	class MyMessage implements Runnable {

		@Override
		public void run() {
			while (true) {

				while (chatClient.messages.size() != 0) {
					Frame[] frames = JFrame.getFrames();
					JSONObject json = chatClient.messages.poll();
					System.out.println(json);
					String sender = String.valueOf(json.get("sender"));
					String receiver=String.valueOf(json.get("receiver"));
					JTextArea chatBox=chat.get(receiver+"|"+sender);
					chatBox.append(sender + " : " + String.valueOf(json.get("message")) + "\n");

				}
			}

		}

	}

}
