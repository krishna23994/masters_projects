package dmsd_project;

import java.awt.FlowLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.List;
import java.util.Map;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.table.DefaultTableModel;

public class AdminUI {

	JTable jt;
	JFrame addDoc=new JFrame("Add Document Copy");
	JFrame searchCopy=new JFrame("Search Document Copy");
	JFrame addReader=new JFrame("Add Reader");
	JFrame printBranch=new JFrame("Branch Information");
	JFrame topBooks=new JFrame("Top Books");
	JFrame topBorrowers=new JFrame("Top Borrowers");
	JFrame topBooksOfYear=new JFrame("Top books of the year");
	JFrame avgFine=new JFrame("Average fine paid by a customer");
	public void addDocumentCopy()
	{
		addDoc.setVisible(true);
		JPanel searchPanel=new JPanel(new FlowLayout());
		JLabel docLabel=new JLabel("Enter document id");
		JTextField docidField=new JTextField(20);
		JLabel copyNoLable=new JLabel("Enter copy number");
		JTextField copyNo=new JTextField(20);
		JLabel positionLabel=new JLabel("Enter position");
		JTextField pos=new JTextField(20);
		JLabel libLabel=new JLabel("Enter library id");
		JTextField libId=new JTextField(20);
		JButton addBtn=new JButton("Add");
		searchPanel.add(docLabel);
		searchPanel.add(docidField);
		searchPanel.add(copyNoLable);
		searchPanel.add(copyNo);
		searchPanel.add(positionLabel);
		searchPanel.add(pos);
		searchPanel.add(libLabel);
		searchPanel.add(libId);
		searchPanel.add(addBtn);
		addDoc.add(searchPanel);
		addDoc.setSize(700, 500);
		addDoc.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		addBtn.addActionListener(new ActionListener() {
			
			@Override
			public void actionPerformed(ActionEvent e) {
				String docId=docidField.getText();
				String copyId=copyNo.getText();
				String position=pos.getText();
				String lib=libId.getText();
				if(docId.equals("")||copyId.equals("")||position.equals("")||lib.equals(""))
				{
					JOptionPane.showMessageDialog(addDoc, "Please enter all details", "Error", JOptionPane.ERROR_MESSAGE);
				}
				else
				{
					if(Administrator.addDocCopy(docId, copyId, position, lib).equals(StringConstants.SUCCESS))
							{
						JOptionPane.showMessageDialog(addDoc, "Document Added Successfully", "Success", JOptionPane.PLAIN_MESSAGE);
						addDoc.dispose();
							}
					else
					{
						JOptionPane.showMessageDialog(addDoc, "Document insertion error", "Error", JOptionPane.ERROR_MESSAGE);
					}
				}
				
			}
		});
	}
	


public void searchCopy()
{
	searchCopy.setVisible(true);
	JPanel searchPanel=new JPanel(new FlowLayout());
	JLabel docLabel=new JLabel("Enter document id");
	JTextField docidField=new JTextField(20);
	JLabel copyNoLable=new JLabel("Enter copy number");
	JTextField copyNo=new JTextField(20);
	JLabel libLabel=new JLabel("Enter library id");
	JTextField libId=new JTextField(20);
	JButton searchBtn=new JButton("Search");
	searchPanel.add(docLabel);
	searchPanel.add(docidField);
	searchPanel.add(copyNoLable);
	searchPanel.add(copyNo);
	searchPanel.add(libLabel);
	searchPanel.add(libId);
	searchPanel.add(searchBtn);
	searchCopy.add(searchPanel);
	searchCopy.setSize(700, 300);
	searchCopy.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
	searchBtn.addActionListener(new ActionListener() {
		
		@Override
		public void actionPerformed(ActionEvent e) {
			String docId=docidField.getText();
			String copyId=copyNo.getText();
			String lib=libId.getText();
			if(docId.equals("")||copyId.equals("")||lib.equals(""))
			{
				JOptionPane.showMessageDialog(addDoc, "Please enter all details", "Error", JOptionPane.ERROR_MESSAGE);
			}
			else
			{
				List<Map<Object, Object>> lst=Administrator.getCopyStatus(copyId, docId, lib);
				for(Map<Object,Object> map:lst)
				{
					String status=String.valueOf(map.get("status"));
					if(status.equalsIgnoreCase("BORROW"))
					{
						JOptionPane.showMessageDialog(addDoc, "Status :"+status, "Status", JOptionPane.PLAIN_MESSAGE);
					}
					else if(status.equalsIgnoreCase("RESERVE"))
					{
						JOptionPane.showMessageDialog(addDoc, "Status :"+status, "Status", JOptionPane.PLAIN_MESSAGE);
					}
					else
					{
						JOptionPane.showMessageDialog(addDoc, "Status :AVAILABLE", "Status", JOptionPane.PLAIN_MESSAGE);
					}
	
				}
				
			}
			
		}
	});
}


public void addReader()
{
	addReader.setVisible(true);
	JPanel searchPanel=new JPanel(new FlowLayout());
	JLabel readerLabel=new JLabel("Enter reader ID");
	JTextField readerIdField=new JTextField(20);
	JLabel rtypeLabel=new JLabel("Enter reader type");
	JTextField rtype=new JTextField(20);
	JLabel rnameLabel=new JLabel("Enter reader name");
	JTextField rname=new JTextField(20);
	JLabel raddressLabel=new JLabel("Enter reader address");
	JTextField raddressField=new JTextField(20);
	JButton addBtn=new JButton("Add");
	searchPanel.add(readerLabel);
	searchPanel.add(readerIdField);
	searchPanel.add(rtypeLabel);
	searchPanel.add(rtype);
	searchPanel.add(rnameLabel);
	searchPanel.add(rname);
	searchPanel.add(raddressLabel);
	searchPanel.add(raddressField);
	searchPanel.add(addBtn);
	addReader.add(searchPanel);
	addReader.setSize(1100, 300);
	addReader.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
	addBtn.addActionListener(new ActionListener() {
		
		@Override
		public void actionPerformed(ActionEvent e) {
			String rId=readerIdField.getText();
			String rType=rtype.getText();
			String rName=rname.getText();
			String rAddress=raddressField.getText();
			if(rId.equals("")||rType.equals("")||rName.equals("")||rAddress.equals(""))
			{
				JOptionPane.showMessageDialog(addDoc, "Please enter all details", "Error", JOptionPane.ERROR_MESSAGE);
			}
			else
			{
				if(Administrator.addReader(rId, rName, rType, rAddress).equals(StringConstants.SUCCESS))
						{
					JOptionPane.showMessageDialog(addDoc, "Reader Added Successfully", "Success", JOptionPane.PLAIN_MESSAGE);
					addDoc.dispose();
						}
				else
				{
					JOptionPane.showMessageDialog(addDoc, "Reader insertion error", "Error", JOptionPane.ERROR_MESSAGE);
				}
			}
			
		}
	});
}

public void printBranchInfo()
{
	jt=new JTable();
	List<Map<Object, Object>> list=Administrator.getBranchInfo();
	DefaultTableModel model = (DefaultTableModel) jt.getModel();
	model.setRowCount(0);
	model.setColumnIdentifiers(list.get(0).keySet().toArray());
	int i=0;
	for(Map<Object,Object> map:list)
	{
     		
	  Object[] rowData=new Object[map.size()];	
	  int j=0;
		for(Object o:map.keySet())
		{
			rowData[j]=map.get(o);
			j++;
		}
		model.insertRow(i, rowData);
		i++;
	}
	jt.setBounds(30,40,200,300);          
	JScrollPane sp=new JScrollPane(jt);
	printBranch.setVisible(true);
	JPanel searchPanel=new JPanel(new FlowLayout());
	searchPanel.add(sp);
	printBranch.add(searchPanel);
	printBranch.setSize(800, 500);
	printBranch.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
}

public void topBooks()
{
	jt=new JTable();
	jt.setBounds(30,40,200,300);          
	JScrollPane sp=new JScrollPane(jt);
	topBooks.setVisible(true);
	JPanel searchPanel=new JPanel(new FlowLayout());
	JLabel libLabel=new JLabel("Enter library id");
	JTextField libId=new JTextField(20);
	JButton searchBtn=new JButton("Search");
	searchPanel.add(libLabel);
	searchPanel.add(libId);
	searchPanel.add(searchBtn);
	searchPanel.add(sp);
	topBooks.add(searchPanel);
	topBooks.setSize(800, 500);
	topBooks.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
	searchBtn.addActionListener(new ActionListener() {
		
		@Override
		public void actionPerformed(ActionEvent e) {
			String libid=libId.getText();
			List<Map<Object, Object>> list=Administrator.getTopBooks(libid);
			DefaultTableModel model = (DefaultTableModel) jt.getModel();
			model.setRowCount(0);
			model.setColumnIdentifiers(list.get(0).keySet().toArray());
			int i=0;
			for(Map<Object,Object> map:list)
			{
		     		
			  Object[] rowData=new Object[map.size()];	
			  int j=0;
				for(Object o:map.keySet())
				{
					rowData[j]=map.get(o);
					j++;
				}
				model.insertRow(i, rowData);
				i++;
			}
			
		}
	});
}




public void topBorrowers()
{
	jt=new JTable();
	jt.setBounds(30,40,200,300);          
	JScrollPane sp=new JScrollPane(jt);
	topBorrowers.setVisible(true);
	JPanel searchPanel=new JPanel(new FlowLayout());
	JLabel libLabel=new JLabel("Enter library id");
	JTextField libId=new JTextField(20);
	JButton searchBtn=new JButton("Search");
	searchPanel.add(libLabel);
	searchPanel.add(libId);
	searchPanel.add(searchBtn);
	searchPanel.add(sp);
	topBorrowers.add(searchPanel);
	topBorrowers.setSize(800, 500);
	topBorrowers.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
	searchBtn.addActionListener(new ActionListener() {
		
		@Override
		public void actionPerformed(ActionEvent e) {
			String libid=libId.getText();
			List<Map<Object, Object>> list=Administrator.getTopBorrowers(libid);
			DefaultTableModel model = (DefaultTableModel) jt.getModel();
			model.setRowCount(0);
			model.setColumnIdentifiers(list.get(0).keySet().toArray());
			int i=0;
			for(Map<Object,Object> map:list)
			{
		     		
			  Object[] rowData=new Object[map.size()];	
			  int j=0;
				for(Object o:map.keySet())
				{
					rowData[j]=map.get(o);
					j++;
				}
				model.insertRow(i, rowData);
				i++;
			}
			
		}
	});
}


public void topBooksofYear()
{
	jt=new JTable();
	jt.setBounds(30,40,200,300);          
	JScrollPane sp=new JScrollPane(jt);
	topBooksOfYear.setVisible(true);
	JPanel searchPanel=new JPanel(new FlowLayout());
	JLabel yearLabel=new JLabel("Enter year");
	JTextField yearField=new JTextField(20);
	JButton searchBtn=new JButton("Search");
	searchPanel.add(yearLabel);
	searchPanel.add(yearField);
	searchPanel.add(searchBtn);
	searchPanel.add(sp);
	topBooksOfYear.add(searchPanel);
	topBooksOfYear.setSize(800, 500);
	topBooksOfYear.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
	searchBtn.addActionListener(new ActionListener() {
		
		@Override
		public void actionPerformed(ActionEvent e) {
			String year=yearField.getText();
			List<Map<Object, Object>> list=Administrator.getTopBooksofYear(year);
			DefaultTableModel model = (DefaultTableModel) jt.getModel();
			model.setRowCount(0);
			model.setColumnIdentifiers(list.get(0).keySet().toArray());
			int i=0;
			for(Map<Object,Object> map:list)
			{
		     		
			  Object[] rowData=new Object[map.size()];	
			  int j=0;
				for(Object o:map.keySet())
				{
					rowData[j]=map.get(o);
					j++;
				}
				model.insertRow(i, rowData);
				i++;
			}
			
		}
	});
}

public void avgFine()
{
	jt=new JTable();
	List<Map<Object, Object>> list=Administrator.getAvgPaidFine();
	DefaultTableModel model = (DefaultTableModel) jt.getModel();
	model.setRowCount(0);
	model.setColumnIdentifiers(list.get(0).keySet().toArray());
	int i=0;
	for(Map<Object,Object> map:list)
	{
     		
	  Object[] rowData=new Object[map.size()];	
	  int j=0;
		for(Object o:map.keySet())
		{
			rowData[j]=map.get(o);
			j++;
		}
		model.insertRow(i, rowData);
		i++;
	}
	jt.setBounds(30,40,200,300);          
	JScrollPane sp=new JScrollPane(jt);
	avgFine.setVisible(true);
	JPanel searchPanel=new JPanel(new FlowLayout());
	searchPanel.add(sp);
	avgFine.add(searchPanel);
	avgFine.setSize(800, 500);
	avgFine.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
}

}