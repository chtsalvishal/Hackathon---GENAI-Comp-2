view: customers {
  sql_table_name: `vishal-sandpit-474523.gold.dim_customers` ;;

  dimension: customer_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.customer_id ;;
    label: "Customer ID"
    tags: ["pii"]
  }

  dimension: customer_name {
    type: string
    sql: ${TABLE}.customer_name ;;
    label: "Customer Name"
    tags: ["pii"]
  }

  dimension: email {
    type: string
    sql: ${TABLE}.email ;;
    label: "Email"
    tags: ["pii"]
    hidden: yes
  }

  dimension: country {
    type: string
    sql: ${TABLE}.country ;;
    label: "Country"
    map_layer_name: countries
  }

  dimension: city {
    type: string
    sql: ${TABLE}.city ;;
    label: "City"
  }

  dimension: customer_segment {
    type: string
    sql: ${TABLE}.customer_segment ;;
    label: "Segment"
    description: "Bronze / Silver / Gold / Platinum based on LTV"
    html: {% if value == 'Platinum' %}<span style="color:#8B0000;font-weight:bold">{{ value }}</span>
          {% elsif value == 'Gold' %}<span style="color:#DAA520;font-weight:bold">{{ value }}</span>
          {% elsif value == 'Silver' %}<span style="color:#708090;font-weight:bold">{{ value }}</span>
          {% else %}<span style="color:#CD7F32">{{ value }}</span>
          {% endif %} ;;
  }

  dimension: churn_risk {
    type: string
    sql: ${TABLE}.churn_risk ;;
    label: "Churn Risk"
    html: {% if value == 'Churned' %}<span style="color:red;font-weight:bold">{{ value }}</span>
          {% elsif value == 'At Risk' %}<span style="color:orange;font-weight:bold">{{ value }}</span>
          {% elsif value == 'Cooling' %}<span style="color:#DAA520">{{ value }}</span>
          {% else %}<span style="color:green">{{ value }}</span>
          {% endif %} ;;
  }

  dimension: days_since_last_purchase {
    type: number
    sql: ${TABLE}.days_since_last_purchase ;;
    label: "Days Since Last Purchase"
  }

  dimension_group: created {
    type: time
    timeframes: [date, month, year, quarter]
    sql: ${TABLE}.created_date ;;
    label: "Created"
    datatype: date
  }

  dimension_group: last_purchase {
    type: time
    timeframes: [date, month, year]
    sql: ${TABLE}.last_purchase_date ;;
    label: "Last Purchase"
    datatype: date
  }

  dimension: first_purchase_date {
    type: date
    sql: ${TABLE}.first_purchase_date ;;
    label: "First Purchase Date"
  }

  measure: count {
    type: count
    label: "Customer Count"
    drill_fields: [customer_id, customer_name, customer_segment, churn_risk]
  }

  measure: total_lifetime_value {
    type: sum
    sql: ${TABLE}.total_lifetime_value ;;
    label: "Total LTV"
    value_format_name: usd
    drill_fields: [customer_id, customer_name, customer_segment]
  }

  measure: avg_lifetime_value {
    type: average
    sql: ${TABLE}.total_lifetime_value ;;
    label: "Avg LTV"
    value_format_name: usd
  }

  measure: avg_order_value {
    type: average
    sql: ${TABLE}.avg_order_value ;;
    label: "Avg Order Value"
    value_format_name: usd
  }

  measure: at_risk_customers {
    type: count
    filters: [churn_risk: "At Risk,Churned"]
    label: "At Risk / Churned Customers"
  }

  measure: platinum_customers {
    type: count
    filters: [customer_segment: "Platinum"]
    label: "Platinum Customers"
  }
}
