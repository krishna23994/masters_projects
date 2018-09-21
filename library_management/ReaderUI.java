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

public class ReaderUI {
	JTable jt;
	JFrame searchDoc=new JFrame("Search Document");
	JFrame reserveDoc=new JFrame("Reserve Document");
	JFrame borrowDoc=new JFrame("Borrow Document");
	JFrame returnDoc=new JFrame("Return Document");
	JFrame computeFine=new JFrame("Compute Fine");
	JFrame printPublishers=new JFrame("Print Publishers");
	public  void searchDocScreen()
	{
		         
		jt=new JTable();
		jt.setBounds(30,40,200,300);          
		JScrollPane sp=new JScrollPane(jt);
		searchDoc.setVisible(true);
		JPanel searchPanel=new JPanel(new FlowLayout());
		JLabel docLabel=new JLabel("Enter document id");
		JTextField docidField=new JTextField(20);
		JLabel docTitleLabel=new JLabel("Enter document title");
		JTextField docTitle=new JTextField(20);
		JLabel docPubLabel=new JLabel("Enter document publisher name");
		JTextField docPub=new JTextField(20);
		JButton searchBtn=new JButton("Search");
		searchPanel.add(docLabel);
		searchPanel.add(docidField);
		searchPanel.add(docTitleLabel);
		searchPanel.add(docTitle);
		searchPanel.add(docPubLabel);
		searchPanel.add(docPub);
		searchPanel.add(searchBtn);
		searchPanel.add(sp);
		/*sp.setVisible(false);*/
		searchDoc.add(searchPanel);
		searchDoc.setSize(800, 500);
		searchDoc.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		searchBtn.addActionListener(new ActionListener() {
			
			@Override
			public void actionPerformed(ActionEvent e) {
				List<Map<Object, Object>> list=Reader.getDocumentsList(docidField.getText(), docTitle.getText(), docPub.getText());
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
	
	public void reserveDocument(String readerId)
	{
		jt=new JTable();
		List<Map<Object, Object>> list=Reader.getDocumentsList("reserve", "", "");
		DefaultTableModel model = (DefaultTableModel) jt.getModel();
		model.setRowCount(0);
		model.setColumnIdentifiers(list.get(0).keySet().toArray());
		int i=0;
		int dialogButton = JOptionPane.YES_NO_OPTION;
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
		reserveDoc.setVisible(true);
		JPanel searchPanel=new JPanel(new FlowLayout());
		searchPanel.add(sp);
		reserveDoc.add(searchPanel);
		reserveDoc.setSize(800, 500);
		reserveDoc.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		jt.addMouseListener(new MouseAdapter() {
			@Override
			public void mouseClicked(MouseEvent arg0) {
				int dialogResult = JOptionPane.showConfirmDialog (null, "Would You Like to reserve this document copy?","Warning",dialogButton);
				if(dialogResult==JOptionPane.YES_OPTION)
				{
				int row=jt.getSelectedRow();
				String libId=String.valueOf(jt.getValueAt(row, 1));
				String docId=String.valueOf(jt.getValueAt(row, 2));
				String copyNo=String.valueOf(jt.getValueAt(row, 3));
				Reader.reserveDocument(copyNo, docId, libId, readerId);
				}
				
			}
		});
	}
	
	public void borrowDocument(String readerId)
	{
		jt=new JTable();
		List<Map<Object, Object>> list=Reader.getReservedDocuments(readerId);
		DefaultTableModel model = (DefaultTableModel) jt.getModel();
		model.setRowCount(0);
		model.setColumnIdentifiers(list.get(0).keySet().toArray());
		int i=0;
		int dialogButton = JOptionPane.YES_NO_OPTION;
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
		borrowDoc.setVisible(true);
		JPanel searchPanel=new JPanel(new FlowLayout());
		searchPanel.add(sp);
		borrowDoc.add(searchPanel);
		borrowDoc.setSize(800, 500);
		borrowDoc.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		jt.addMouseListener(new MouseAdapter() {
			@Override
			public void mouseClicked(MouseEvent arg0) {
				int dialogResult = JOptionPane.showConfirmDialog (null, "Would You Like to borrow this document copy?","Warning",dialogButton);
				if(dialogResult==JOptionPane.YES_OPTION)
				{
				int row=jt.getSelectedRow();
				String libId=String.valueOf(jt.getValueAt(row, 0));
				String docId=String.valueOf(jt.getValueAt(row, 1));
				String copyNo=String.valueOf(jt.getValueAt(row, 2));
				String resNo=String.valueOf(jt.getValueAt(row, 3));
				Reader.borrowDocument(resNo, readerId, docId, copyNo, libId);
				}
				
			}
		});
	}
	
	public void returnDoc(String readerId)
	{
		jt=new JTable();
		List<Map<Object, Object>> list=Reader.getBorrowDocuments(readerId);
		DefaultTableModel model = (DefaultTableModel) jt.getModel();
		model.setRowCount(0);
		model.setColumnIdentifiers(list.get(0).keySet().toArray());
		int i=0;
		int dialogButton = JOptionPane.YES_NO_OPTION;
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
		returnDoc.setVisible(true);
		JPanel searchPanel=new JPanel(new FlowLayout());
		searchPanel.add(sp);
		returnDoc.add(searchPanel);
		returnDoc.setSize(800, 500);
		returnDoc.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		jt.addMouseListener(new MouseAdapter() {
			@Override
			public void mouseClicked(MouseEvent arg0) {
				int dialogResult = JOptionPane.showConfirmDialog (null, "Would You Like to return this document copy?","Warning",dialogButton);
				if(dialogResult==JOptionPane.YES_OPTION)
				{
				int row=jt.getSelectedRow();
				String libId=String.valueOf(jt.getValueAt(row, 0));
				String docId=String.valueOf(jt.getValueAt(row, 1));
				String copyNo=String.valueOf(jt.getValueAt(row, 2));
				String borNo=String.valueOf(jt.getValueAt(row, 3));
				Reader.returnDocument(readerId, docId, copyNo, libId, borNo);
				}
				
			}
		});
	}

	public void computeFine(String readerId)
	{
		jt=new JTable();
		List<Map<Object, Object>> list=Reader.getBorrowDocuments(readerId);
		DefaultTableModel model = (DefaultTableModel) jt.getModel();
		model.setRowCount(0);
		model.setColumnIdentifiers(list.get(0).keySet().toArray());
		int i=0;
		int dialogButton = JOptionPane.YES_NO_OPTION;
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
		computeFine.setVisible(true);
		JPanel searchPanel=new JPanel(new FlowLayout());
		searchPanel.add(sp);
		computeFine.add(searchPanel);
		computeFine.setSize(800, 500);
		computeFine.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		jt.addMouseListener(new MouseAdapter() {
			@Override
			public void mouseClicked(MouseEvent arg0) {
				int dialogResult = JOptionPane.showConfirmDialog (null, "Would You Like to compute fine for this document copy?","Warning",dialogButton);
				if(dialogResult==JOptionPane.YES_OPTION)
				{
				int row=jt.getSelectedRow();
				String libId=String.valueOf(jt.getValueAt(row, 0));
				String docId=String.valueOf(jt.getValueAt(row, 1));
				String copyNo=String.valueOf(jt.getValueAt(row, 2));
				String borNo=String.valueOf(jt.getValueAt(row, 3));
				List<Map<Object, Object>> lst=Reader.computeFine(readerId, docId, copyNo, libId, borNo);
				for(Map<Object,Object> map:lst)
				{
					for(Object o:map.keySet())
					{
						
						JOptionPane.showMessageDialog(null, "Fine amount is $"+String.valueOf(map.get(o)), "Fine amount", JOptionPane.WARNING_MESSAGE);
					}
				}
				}
				
			}
		});
	}
	
	
	public void printPublishers()
	{
		jt=new JTable();
		List<Map<Object, Object>> list=Reader.getPubDetails();
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
		printPublishers.setVisible(true);
		JPanel searchPanel=new JPanel(new FlowLayout());
		searchPanel.add(sp);
		printPublishers.add(searchPanel);
		printPublishers.setSize(800, 500);
		printPublishers.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
	}

}
