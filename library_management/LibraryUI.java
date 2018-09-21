package dmsd_project;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.Frame;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Toolkit;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.DefaultListModel;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.ListSelectionModel;

public class LibraryUI implements ActionListener {

	JFrame mainFrame = new JFrame("Reader-Library Management System");
	JFrame mainFrame2 = new JFrame("Admin-Library Management System");
	JFrame mainFrame1 = new JFrame();
	DefaultListModel defaultListModel = new DefaultListModel<>();
	Object[] data;
	JList list = new JList(defaultListModel);;
	JButton sendMessage;
	JTextField messageBox;
	JTextArea chatBox;
	JTextField userName;
	JFrame preFrame;
	String readerId;
	JLabel readerLogin;
	JLabel chooseUsernameLabel;
	JButton readerLoginBtn;
	JLabel adminLoginLabel;
	JLabel adminUsernameLabel;
	JTextField adminUsername;
	JLabel adminPasswordLabel;
	JPasswordField adminPassword;
	JButton adminLogin;
	ReaderUI readerUI = new ReaderUI();
	AdminUI adminUI=new AdminUI();
	Dimension dim = Toolkit.getDefaultToolkit().getScreenSize();
	static String status;

	public static void main(String[] args) {
		LibraryUI mainGUI = new LibraryUI();
		mainGUI.loginPanel();
	}

	public void loginPanel() {
		mainFrame.setVisible(false);
		preFrame = new JFrame("Library Management System");
		preFrame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		userName = new JTextField(20);
		readerLogin = new JLabel("Reader Login -");
		chooseUsernameLabel = new JLabel("Enter your reader ID");
		readerLoginBtn = new JButton("Login");
		adminLoginLabel = new JLabel("Admin Login -");
		adminUsernameLabel = new JLabel("Username");
		adminUsername = new JTextField(20);
		adminPasswordLabel = new JLabel("Password");
		adminPassword = new JPasswordField(20);
		adminLogin = new JButton("Login");
		JPanel prePanel = new JPanel(new FlowLayout());
		JPanel adminPanel = new JPanel(new FlowLayout());
		prePanel.add(readerLogin);
		prePanel.add(chooseUsernameLabel);
		prePanel.add(userName);
		prePanel.add(readerLoginBtn);
		adminPanel.add(adminLoginLabel);
		adminPanel.add(adminUsernameLabel);
		adminPanel.add(adminUsername);
		adminPanel.add(adminPasswordLabel);
		adminPanel.add(adminPassword);
		adminPanel.add(adminLogin);
		prePanel.add(adminPanel);
		preFrame.add(prePanel);
		preFrame.setVisible(true);
		preFrame.setSize(1000, 300);
		preFrame.setLocation(dim.width / 2 - preFrame.getSize().width / 2,
				dim.height / 2 - preFrame.getSize().height / 2);
		readerLoginBtn.addActionListener(this);
		readerLoginBtn.setActionCommand("readerLogin");
		adminLogin.setActionCommand("adminLogin");
		adminLogin.addActionListener(this);
	}

	public void userScreen() {
		preFrame.setVisible(false);
		mainFrame.setVisible(true);
		JButton search = new JButton("Search document");
		JButton reserve = new JButton("Reserve document");
		JButton checkout = new JButton("Checkout");
		JButton returnDoc = new JButton("Return document");
		JButton fine = new JButton("Compute fine");
		JButton publisher = new JButton("Get publisher details");
		search.addActionListener(this);
		returnDoc.addActionListener(this);
		reserve.addActionListener(this);
		checkout.addActionListener(this);
		fine.addActionListener(this);
		publisher.addActionListener(this);
		search.setActionCommand("search");
		returnDoc.setActionCommand("return");
		reserve.setActionCommand("reserve");
		checkout.setActionCommand("checkout");
		fine.setActionCommand("fine");
		publisher.setActionCommand("publisher");
		JPanel userPanel = new JPanel(new FlowLayout());
		userPanel.add(search);
		userPanel.add(returnDoc);
		userPanel.add(reserve);
		userPanel.add(checkout);
		userPanel.add(fine);
		userPanel.add(publisher);
		mainFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		mainFrame.add(userPanel);
		mainFrame.setSize(600, 200);
		mainFrame.setLocation(dim.width / 2 - mainFrame.getSize().width / 2,
				dim.height / 2 - mainFrame.getSize().height / 2);
	}

	public void mainScreen() {
		preFrame.setVisible(false);
		mainFrame2.setVisible(true);
		JButton addDoc = new JButton("Add document copy");
		JButton searchDoc = new JButton("Search Document copy");
		JButton addReader = new JButton("Add New Reader");
		JButton branchInfo = new JButton("Print Branch information");
		JButton freqBor = new JButton("Print frequent borrowers");
		JButton freqBooks = new JButton("Print frequent borrowed books");
		JButton popBooks = new JButton("Print popular books");
		JButton avgFine = new JButton("Compute average fine");
		addDoc.addActionListener(this);
		searchDoc.addActionListener(this);
		branchInfo.addActionListener(this);
		freqBor.addActionListener(this);
		freqBooks.addActionListener(this);
		popBooks.addActionListener(this);
		addReader.addActionListener(this);
		avgFine.addActionListener(this);
		addDoc.setActionCommand("addDoc");
		searchDoc.setActionCommand("searchDoc");
		branchInfo.setActionCommand("branch");
		freqBor.setActionCommand("freqBor");
		addReader.setActionCommand("addReader");
		popBooks.setActionCommand("popBooks");
		freqBooks.setActionCommand("freqBooks");
		avgFine.setActionCommand("avgFine");
		JPanel userPanel = new JPanel(new FlowLayout());
		userPanel.add(addDoc);
		userPanel.add(searchDoc);
		userPanel.add(addReader);
		userPanel.add(branchInfo);
		userPanel.add(freqBor);
		userPanel.add(freqBooks);
		userPanel.add(popBooks);
		userPanel.add(avgFine);
		mainFrame2.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		mainFrame2.add(userPanel);
		mainFrame2.setSize(600, 200);
		mainFrame2.setLocation(dim.width / 2 - mainFrame.getSize().width / 2,
				dim.height / 2 - mainFrame.getSize().height / 2);
	}

	@Override
	public void actionPerformed(ActionEvent e) {
		String command = e.getActionCommand();
		if (command.equals("readerLogin")) {
			if (userName.getText().equals("")) {
				JOptionPane.showMessageDialog(preFrame, "Invalid reader", "Error", JOptionPane.ERROR_MESSAGE);
			} else {
				String status = Reader.readerLogin(userName.getText());
				if (status.equals(StringConstants.SUCCESS)) {
					readerId = userName.getText();
					userScreen();
				} else {
					System.out.println("Invalid reader");
				}
			}
		} else if (command.equals("adminLogin")) {

			if (adminUsername.getText().equals("") || String.valueOf(adminPassword.getPassword()).equals("")) {
				JOptionPane.showMessageDialog(preFrame, "Invalid username or password", "Error",
						JOptionPane.ERROR_MESSAGE);
			} else {
				String status = Administrator.adminLogin(adminUsername.getText(),
						String.valueOf(adminPassword.getPassword()));
				if (status.equals(StringConstants.SUCCESS)) {
					mainScreen();
				} else {
					System.out.println("Invalid login credentials");
				}
			}

		}
		else if(command.equals("publisher"))
		{
			readerUI.printPublishers();
		}

		else if (command.equals("search")) {
			readerUI.searchDocScreen();
		}

		else if (command.equals("return")) {
			readerUI.returnDoc(readerId);

		} else if (command.equals("reserve")) {
			readerUI.reserveDocument(readerId);

		} else if (command.equals("checkout")) {
			readerUI.borrowDocument(readerId);

		} else if (command.equals("fine")) {
			readerUI.computeFine(readerId);

		} else if (command.equals("addDoc")) {
			adminUI.addDocumentCopy();

		}

		else if (command.equals("searchDoc")) {
			adminUI.searchCopy();

		} else if (command.equals("branch")) {
			adminUI.printBranchInfo();
			

		} else if (command.equals("freqBor")) {
			adminUI.topBorrowers();

		} else if (command.equals("addReader")) {
			adminUI.addReader();

		} else if (command.equals("popBooks")) {
			adminUI.topBooksofYear();

		} else if (command.equals("freqBooks")) {
			adminUI.topBooks();

		} else if (command.equals("avgFine")) {
			adminUI.avgFine();

		}

	}

}
